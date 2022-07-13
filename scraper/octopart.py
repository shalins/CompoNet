import requests
import json
import os

from tqdm.notebook import tqdm

from constants import *
from utils import *

class OctopartScraper():
    def __init__(self, user_agent, perimeterx_key):
        self.user_agent = user_agent
        self.perimeterx_key = perimeterx_key

    def get_cookies(self):
        # For some reason this cookie is what is required in order to authenticate that we are
        # indeed a genuine user and not trigger a captcha page.
        cookies = {
            '_px': self.perimeterx_key,
        }
        return cookies

    def get_header(self):
        header = {
            'user-agent': self.user_agent,
        }
        return header

    def get_payload(self, start=0, limit=10, f1_idx=0, f2_idx=0, f3_idx=0):
        from aluminum_electrolytic_categories import capacitance, voltage_rating_dc, voltage_rating_ac, voltage_rating
        QUERY_STRING = read_file_as_string(f"{CURRENT_WD}/{QUERY_FILENAME}")
        payload = {
            'operationName': 'PricesViewSearch',
            'variables': {
                'country': 'US',
                'currency': 'USD',
                'filters': {
                    'category_id': [
                        '6331',
                    ],
                    'capacitance': [
                        capacitance[f1_idx],
                    ],
                    'voltagerating_ac_': [
                        voltage_rating_ac[f2_idx],
                    ]            
                },
                'in_stock_only': False,
                'limit': limit,
                'start': start,
            },
            'query': QUERY_STRING,
        }
        return payload

    def request(self, i, j, n, px): 
        header = self.get_header()
        payload = self.get_payload(start=n, limit=MAX_RESULTS, f1_idx=i, f2_idx=j)
        cookies = self.get_cookies(px)
        response = requests.post(API_ENDPOINT, cookies=cookies, headers=header, json=payload)
        try: 
            return response.json(), len(response.json()['data']['search']['results'])
        except:
            if 'text/html' in response.headers['Content-Type']:
                print('Got an HTML page!', response.content)
                return {}, -1
            else:
                print("No results found!")
                return {}, 0

    def collect(data, f1_idx, f1_value, f2_idx, f2_value, page):
        # First save the data to a file just so we're not screwed in case something goes wrong.
        filename = create_data_filename("aluminum_electrolytic", "capacitance", f1_idx, f1_value, "voltage_rating_ac", f2_idx, f2_value, page)
        filepath = f"{TMP_DIR}{filename}"
        save_data(data, filepath)
        
    def save_all(name, collection):
        filename = f"{name}.json"
        filepath = f"{SAVE_DIR}{filename}"
        save_data(collection, filepath)

    def run(px, page_start_idx=0, f1_idx=0, f2_idx=0, f3_idx=0):
        f1_reached = False
        f2_reached = False
        page_start_reached = False
        
        for i in tqdm(range(0, len(capacitance))):
            if i < f1_idx and not f1_reached:
                continue
            f1_reached = True
            
            for j in tqdm(range(0, len(voltage_rating_ac))):
                if j < f2_idx and not f2_reached:
                    continue
                f2_reached = True
                
                for n in tqdm(range(0, MAX_PAGE_OFFSET, 100)):
                    if n < page_start_idx and not page_start_reached:
                        continue
                    page_start_reached = True
                    
                    response, num_results = request(i, j, n, px)
                    
                    if num_results == 0:
                        break
                    elif num_results == -1:
                        print(f"Filter 1 IDX: {i}, Filter 2 IDX {j}, Page start IDX: {n}")
                        return
                        
                    # Collect the data
                    collect(response, i, capacitance[i], j, voltage_rating_ac[j], n)
                    
                    if num_results < 100:
                        print("There were <100 results, and we've reached the end of the pagination.")
                        break