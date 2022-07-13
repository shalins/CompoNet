import os

API_ENDPOINT = 'https://octopart.com/api/v4/internal'

CURRENT_WD = os.getcwd()
QUERY_FILENAME = "query_no_seller.txt"

TMP_DIR = f"{CURRENT_WD}/tmp/"
SAVE_DIR = f"{CURRENT_WD}/data/capacitor/aluminum_electrolytic/"
SAVE_FILE_PREFIX = "capacitors"
SAVE_FILE_SUFFIX = "json"

DEFAULT_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36'
MAX_PAGE_OFFSET = 1000
MAX_RESULTS = 100