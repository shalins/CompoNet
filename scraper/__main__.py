import click
import requests
from categories import attributes_cache, categories_cache
from constants import API_ENDPOINT, DEFAULT_USER_AGENT, MAX_PAGE_OFFSET, MAX_RESULTS, SAVE_DIR
from metadata import get_attribute_payload, get_cookies, get_headers, get_parts_payload
from queries import ATTRIBUTE_BUCKET_QUERY, PART_SEARCH_QUERY
from tqdm import tqdm
from tqdm.contrib.itertools import product
from utils import save_data


class OctopartScraper:
    def __init__(self, category, attributes, px, user_agent):
        self.current_spot = None
        self.first_time = True
        self.restarting = False
        self.all_data = {}
        self.category = category
        self.attributes = attributes
        self.perimeterx_key = px
        self.user_agent = user_agent

    def _get_request_params(self):
        cookies = get_cookies(self.perimeterx_key)
        headers = get_headers(self.user_agent)
        return cookies, headers

    def _get_buckets_response(self, attribute_name):
        query = ATTRIBUTE_BUCKET_QUERY
        cookies, headers = self._get_request_params()
        payload = get_attribute_payload(
            query=query, category_id=self.category_id, attribute=attribute_name
        )
        response = requests.post(API_ENDPOINT, cookies=cookies, headers=headers, json=payload)
        return response

    def _get_parts_response(self, start, limit, **kwargs):
        query = PART_SEARCH_QUERY
        cookies, headers = self._get_request_params()
        payload = get_parts_payload(
            query=query, category_id=self.category_id, start=start, limit=limit, **kwargs
        )
        response = requests.post(API_ENDPOINT, cookies=cookies, headers=headers, json=payload)
        return response

    def _fetch_attributes(self, response):
        try:
            data = response.json()
            specs = [spec for spec in data["data"]["search"]["spec_aggs"][0]["buckets"]]
            values = [
                spec["float_value"] if spec["float_value"] is not None else spec["display_value"]
                for spec in specs
            ]
            return values, len(values)
        except ValueError:
            return {}, -1

    def _fetch_parts(self, response):
        try:
            data = response.json()
            return data, len(data["data"]["search"]["results"])
        except ValueError:
            return {}, -1
        except TypeError:
            # "No results found, moving on...
            return {}, 0

    def run(self):
        self.category_id = categories_cache[self.category]
        self.attribute_buckets_values = []
        self.attribute_buckets_keys = []

        perimeterx_error = False
        while True:
            if perimeterx_error:
                perimeterx_error = False
                self.restarting = True
                self.perimeterx_key = click.prompt(
                    "Please enter a Perimeter X key:", type=str, default=self.perimeterx_key
                )
                self.user_agent = click.prompt(
                    "Please enter your user-agent header:", type=str, default=self.user_agent
                )

            if len(self.attribute_buckets_keys) != len(self.attributes):
                print("Fetching attribute buckets...")

                for attribute in self.attributes:
                    response = self._get_buckets_response(attribute)
                    results, count = self._fetch_attributes(response)
                    if count == -1:
                        print("PerimeterX Captcha Detected ")
                        perimeterx_error = True
                        break
                    self.attribute_buckets_keys.append(attribute)
                    self.attribute_buckets_values.append(results)
                    print(f"{attribute} (with {count} buckets) fetched!")

            ranges = [range(0, len(a)) for a in self.attribute_buckets_values]
            for tup in product(*ranges, desc="Fetching parts...", position=0, colour="green"):
                if perimeterx_error:
                    break

                if self.restarting and self.current_spot is not None and self.current_spot != tup:
                    continue
                self.restarting = False
                self.current_spot = tup

                arguments = dict(
                    zip(
                        self.attribute_buckets_keys,
                        [
                            self.attribute_buckets_values[idx][value]
                            for (idx, value) in enumerate(tup)
                        ],
                    )
                )
                for start in tqdm(
                    range(0, MAX_PAGE_OFFSET, MAX_RESULTS),
                    desc="Going through pages...",
                    position=1,
                    leave=False,
                    colour="blue",
                ):
                    response = self._get_parts_response(start, MAX_RESULTS, **arguments)
                    results, count = self._fetch_parts(response)

                    if count == 0:
                        break
                    elif count == -1:
                        print("PerimeterX Captcha Detected ")
                        perimeterx_error = True
                        break

                    if self.first_time:
                        self.first_time = False
                        self.all_data = results
                    else:
                        self.all_data["data"]["search"]["results"].extend(
                            results["data"]["search"]["results"]
                        )

                    if count < 100:
                        break

            path = save_data(self.all_data, SAVE_DIR, self.category)
            if perimeterx_error and len(self.all_data) > 0:
                print(f"Saving all intermediate data to {path}...")
            elif not perimeterx_error and len(self.all_data) >= 0:
                print(f"All done fetching components! Saved to file {path}")
                break


def valid(category, attributes):
    """
    Checks if the category and attributes are valid.
    """
    # Check if the category exists
    if category not in categories_cache:
        print(f"Category {category} does not exist!")
        return False

    # Check if the attributes exist
    for attribute in attributes:
        if attribute not in attributes_cache:
            print(f"Attribute {attribute} does not exist!")
            return False

    return True


@click.command()
@click.option(
    "--category",
    "-c",
    help="Component category to scrape from Octopart.",
    default="Ceramic Capacitors",
    prompt='Please enter the component category (e.g. "Ceramic Capacitors")',
)
@click.option(
    "--attributes",
    "-a",
    multiple=True,
    help="Attributes to group the components into smaller buckets for fetching \
        (since Octopart only allows scraping a max of 1000 components per query). ",
    default=["Capacitance", "Voltage"],
    prompt='Please enter the comma-separated and in-order list of (string) attributes to \
        filter by (e.g. ["Capacitance", "Voltage Rating", "Dielectric", "Case/Package"])',
)
@click.option(
    "--px",
    help="Perimeter X key for Captcha bypass.",
    default=None,
    type=str,
    required=True,
    prompt="Please enter a Perimeter X key",
)
@click.option(
    "--user-agent",
    "-u",
    help="User-agent header that allows the Octopart server to recognize the scraper as \
        a human and respond to requests.",
    default=DEFAULT_USER_AGENT,
    prompt="Please enter your user-agent header",
)
def main(category, attributes, px, user_agent):
    category = category.title()
    # Convert from tuple to list.
    attributes = list(map(lambda x: x.title(), attributes))
    if valid(category, attributes):
        print(
            f"Scraping {category} with attributes {attributes}. Perimeter X key: {px}, \
                User Agent: {user_agent}"
        )
        scraper = OctopartScraper(category, list(attributes), px, user_agent)
        scraper.run()
    exit(1)


if __name__ == "__main__":
    main()
