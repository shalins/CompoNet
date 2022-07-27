import os

API_ENDPOINT = "https://octopart.com/api/v4/internal"

CURRENT_WD = os.getcwd()

TMP_DIR = f"{CURRENT_WD}/tmp/"
SAVE_DIR = f"{CURRENT_WD}/scraper/data/"
SAVE_FILE_EXT = "json"
CURRENT_PLACE_FILE = "__current_place.txt"

DEFAULT_USER_AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 \
(KHTML, like Gecko) Chrome/103.0.0.0 Safari/537.36"
MAX_PAGE_OFFSET = 1000
MAX_RESULTS = 100
