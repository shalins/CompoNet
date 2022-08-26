# import signal
import click
import requests
from categories import attributes_cache, categories_cache
from constants import API_ENDPOINT, DEFAULT_USER_AGENT, MAX_PAGE_OFFSET, MAX_RESULTS
from metadata import get_attribute_payload, get_cookies, get_headers, get_parts_payload
from plyer import notification
from queries import ATTRIBUTE_BUCKET_QUERY, PART_SEARCH_QUERY
from tqdm import tqdm
from tqdm.contrib.itertools import product
from utils import Colors, load_current_place, remove_current_place, save_current_place, save_data


class OctopartScraper:
    def __init__(self, category, attributes, px, user_agent):
        self.current_place = load_current_place()
        self.restarting = True
        self.all_data = {}
        self.category = category
        self.attributes = attributes
        self.perimeterx_key = px
        self.user_agent = user_agent
        # signal.signal(signal.SIGUSR1, self._fail_gracefully)
        # signal.siginterrupt(signal.SIGUSR1, False)

    def _fail_gracefully(self, *args):
        if len(self.all_data) > 0:
            path = save_data(self.all_data, self.category, intermediate=True)
            save_current_place(self.current_place)
            print(f"\n{Colors.GREEN}FAILED GRACEFULLY\nSaving all intermediate data to {path}{Colors.ENDC}\n")

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
            print(len(self.all_data))
            try:
                if perimeterx_error:
                    if len(self.all_data) > 0:
                        path = save_data(self.all_data, self.category, intermediate=True)
                        save_current_place(self.current_place)
                        print(
                            f"\n{Colors.GREEN}Saving all intermediate data to {path}{Colors.ENDC}\n"
                        )
                        self.all_data = {}

                    perimeterx_error = False
                    self.restarting = True
                    notification.notify(
                        title="PerimeterX Captcha",
                        message="PerimeterX error, please enter another PerimeterX key.",
                        app_icon="cap.ico",
                        timeout=10,
                    )
                    self.perimeterx_key = click.prompt(
                        f"\n{Colors.BLUE}Please enter a Perimeter X key:{Colors.ENDC}",
                        type=str,
                        default=self.perimeterx_key,
                    )
                    self.user_agent = click.prompt(
                        f"\n{Colors.BLUE}Please enter your user-agent header:{Colors.ENDC}",
                        type=str,
                        default=self.user_agent,
                    )
                    continue

                if len(self.attribute_buckets_keys) != len(self.attributes):
                    print("\n")
                    for attribute in self.attributes:
                        attribute_key = attributes_cache[attribute]
                        response = self._get_buckets_response(attribute_key)
                        results, count = self._fetch_attributes(response)
                        if count == -1:
                            print(f"\n\n{Colors.BOLD}PERIMETERX CAPTCHA DETECTED{Colors.ENDC}\n\n")
                            perimeterx_error = True
                            break
                        self.attribute_buckets_keys.append(attribute_key)
                        self.attribute_buckets_values.append(results)
                        print(
                            f"{Colors.GREEN}Fetched attribute {attribute}, split into"
                            f" {count} buckets.{Colors.ENDC}"
                        )
                    print("\n")
                ranges = [range(0, len(a)) for a in self.attribute_buckets_values]
                for tup in product(
                    *ranges,
                    desc=f"{Colors.GREEN}Fetching Parts{Colors.ENDC}",
                    position=0,
                    colour="green",
                ):
                    if perimeterx_error:
                        break

                    if (
                        self.restarting
                        and self.current_place is not None
                        and self.current_place != tup
                    ):
                        continue
                    self.restarting = False
                    self.current_place = tup

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
                        desc=f"{Colors.BLUE}Fetching Pages{Colors.ENDC}",
                        position=1,
                        colour="blue",
                        leave=False,
                    ):
                        response = self._get_parts_response(start, MAX_RESULTS, **arguments)
                        results, count = self._fetch_parts(response)

                        if count == 0:
                            break
                        elif count == -1:
                            print(f"\n\n{Colors.BOLD}PERIMETERX CAPTCHA DETECTED{Colors.ENDC}\n\n")
                            perimeterx_error = True
                            break

                        if len(self.all_data) <= 0:
                            self.all_data = results
                        else:
                            self.all_data["data"]["search"]["results"].extend(
                                results["data"]["search"]["results"]
                            )

                        if count < 100:
                            break

                if not perimeterx_error and len(self.all_data) > 0:
                    path = save_data(self.all_data, self.category)
                    remove_current_place()
                    print(
                        f"\n{Colors.GREEN}All done fetching components! Saved to file"
                        f" {path}{Colors.ENDC}\n"
                    )
                    break
            except:
                self._fail_gracefully()


def valid(category, attributes):
    """
    Checks if the category and attributes are valid.
    """
    # Check if the category exists
    if category not in categories_cache:
        print(f"{Colors.RED}\nCATEGORY {category} DOES NOT EXIST\n{Colors.ENDC}")
        return False

    # Check if the attributes exist
    for attribute in attributes:
        if attribute not in attributes_cache:
            print(f"{Colors.RED}\nATTRIBUTE {attribute} DOES NOT EXIST\n{Colors.ENDC}")
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
    default=None,
    help=(
        "Attributes to group the components into smaller buckets for fetching (since Octopart only"
        " allows scraping a max of 1000 components per query). \n For example, run python3 scraper"
        " -a 'Capacitance' -a 'Voltage Rating'"
    ),
    required=True,
)
@click.option(
    "--px",
    help="Perimeter X key for Captcha bypass.",
    default=None,
    type=str,
    required=True,
    prompt=f"\n{Colors.BLUE}Please enter a Perimeter X key{Colors.ENDC}",
)
@click.option(
    "--user-agent",
    "-u",
    help=(
        "User-agent header that allows the Octopart server to recognize the scraper as a human and"
        " respond to requests."
    ),
    default=DEFAULT_USER_AGENT,
    prompt=f"\n{Colors.BLUE}Please enter your user-agent header{Colors.ENDC}",
)
def main(category, attributes, px, user_agent):
    # category = category.title()
    # Convert from tuple to list.
    # attributes = list(map(lambda x: x.title(), attributes))
    if valid(category, attributes):
        print("\n\n")
        print(f"{Colors.PURPLE}Category:\t\t {category}{Colors.ENDC}")
        print(f"{Colors.MAGENTA}Attributes:\t\t {attributes}{Colors.ENDC}")
        print(f"{Colors.LIGHT_BLUE}Perimeter X Key:\t {px}{Colors.ENDC}")
        print(f"{Colors.CYAN}User-agent:\t\t {user_agent}{Colors.ENDC}")
        scraper = OctopartScraper(category, list(attributes), px, user_agent)
        scraper.run()
    exit(1)


if __name__ == "__main__":
    main()
