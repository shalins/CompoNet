from typing import List
from typing_extensions import Required
from categories import categories_cache, attributes_cache
from utils import save_data

# from itertools import product
from tqdm.contrib.itertools import product
from constants import MAX_PAGE_OFFSET, MAX_RESULTS, MAX_PAGE_OFFSET
import requests


from metadata import get_cookies, get_headers, get_parts_payload, get_attribute_payload
from queries import PART_SEARCH_QUERY, ATTRIBUTE_BUCKET_QUERY
from constants import API_ENDPOINT
import requests

import click

class OctopartScraper():
    def __init__(self, category, attributes, px, user_agent):
        self.current_spot=None
        self.first_time = True
        self.restarting = False
        self.all_data = {}
        self.category = category
        self.attributes = attributes
        self.perimeterx_key = px
        self.user_agent = user_agent

    def get_request_params(self):
        cookies = get_cookies(self.perimeterx_key)
        headers = get_headers(self.user_agent)
        return cookies, headers

    def get_buckets_response(self, attribute_name):
        query = ATTRIBUTE_BUCKET_QUERY
        cookies, headers = self.get_request_params()
        payload = get_attribute_payload(query=query, category_id=self.category_id, attribute=attribute_name)
        response = requests.post(API_ENDPOINT, cookies=cookies, headers=headers, json=payload)
        return response

    def get_parts_response(self, start, limit, **kwargs):
        query = PART_SEARCH_QUERY
        cookies, headers = self.get_request_params()
        payload = get_parts_payload(query=query, category_id=self.category_id, start=start, limit=limit, **kwargs)
        response = requests.post(API_ENDPOINT, cookies=cookies, headers=headers, json=payload)
        return response

    def fetch_attributes(self, response):
        try:
            data = response.json()
            specs = [spec for spec in data['data']['search']['spec_aggs'][0]['buckets']]
            values = [spec["float_value"] if spec["float_value"] is not None else spec["display_value"] for spec in specs]
            return values, len(values)
        except:
            return {}, -1
            

    def fetch_parts(self, response):
        try:
            data = response.json()
            return data, len(data['data']['search']['results'])
        except:
            if 'text/html' in response.headers['Content-Type']:
                return {}, -1
            else:
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
                self.perimeterx_key = input("""Enter your perimeterx key:""")
                self.user_agent = input("""Enter your User Agent string:""")

            if len(self.attribute_buckets_keys) != len(self.attributes):
                print("Fetching attribute buckets...")

                for attribute in self.attributes:
                    print(f"Fetching {attribute}...")
                    response = self.get_buckets_response(attribute)
                    results, count = self.fetch_attributes(response)
                    if count == -1:
                        print("PerimeterX Captcha Detected ")
                        perimeterx_error = True
                        break
                    self.attribute_buckets_keys.append(attribute)
                    self.attribute_buckets_values.append(results)
                    print(f"{attribute} (with {count} buckets) fetched!")

            ranges = [range(0, len(a)) for a in self.attribute_buckets_values]
            for tup in product(*ranges):
                if perimeterx_error:
                    break

                print("Fetching parts...")

                if self.restarting and self.current_spot != tup:
                    print(f"Skipping {tup}")
                    continue
                self.restarting = False
                self.current_spot = tup

                arguments = dict(zip(self.attribute_buckets_keys, [self.attribute_buckets_values[idx][value] for (idx, value) in enumerate(tup)]))
                for start in range(0, MAX_PAGE_OFFSET, MAX_RESULTS):
                    print(tup, start)
                    response = self.get_parts_response(start, MAX_RESULTS, **arguments)
                    results, count = self.fetch_parts(response)

                    if count == 0:
                        print("No results found, moving on...")
                        break
                    elif count == -1:
                        print("PerimeterX Captcha Detected ")
                        perimeterx_error = True
                        break

                    if self.first_time:
                        self.first_time = False
                        self.all_data = results
                    else:
                        self.all_data['data']['search']['results'].extend(results['data']['search']['results'])

                    if count < 100:
                        print("< 100 results found, moving on...")
                        break

            if perimeterx_error and len(self.all_data) > 0:
                save_data(self.all_data, f"{self.category}.json")
                print("Saving all intermediate data...")
            elif not perimeterx_error and len(self.all_data) >= 0:
                save_data(self.all_data, f"{self.category}.json")
                print(f"All done fetching components! Saved to file {self.category}.json")
                break

@click.command()
@click.option('--category', '-c',
help='Component category to scrape from Octopart.', 
default='Ceramic Capacitors', 
prompt='Please enter the component category (e.g. "Ceramic Capacitors")')
@click.option('--attributes', '-a',
multiple=True,
help='Attributes to group the components into smaller buckets for fetching (since Octopart only allows scraping a max of 1000 components per query). ', 
default=["Capacitance", "Voltage"], 
prompt='Please enter the comma-separated and in-order list of (string) attributes to filter by (e.g. ["Capacitance", "Voltage Rating", "Dielectric", "Case/Package"])')
@click.option('--px', 
help='Perimeter X key for Captcha bypass.', 
default=None, 
required=True,
prompt='Please enter a Perimeter X key')
@click.option('--user-agent', '-u',
help='User-agent header that allows the Octopart server to recognize the scraper as a human and respond to requests.', 
default='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36', 
prompt='Please enter your user-agent header')
def main(category, attributes, px, user_agent):
    print(f"Scraping {category} with attributes {attributes}. Perimeter X key: {px}, User Agent: {user_agent}")
    scraper = OctopartScraper(category, list(attributes), px, user_agent)
    scraper.run()

if __name__ == "__main__":
    main()