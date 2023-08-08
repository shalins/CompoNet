import os

# ZenRows Scraper API
ZENROWS_API_ENDPOINT = "https://api.zenrows.com/v1/"
ZENROWS_API_KEY = "cfb9d7c7fac045991417bae4a9a15db3f469fceb"

API_ENDPOINT = "https://octopart.com/api/v4/internal"

CURRENT_WD = os.getcwd()

TMP_DIR = f"{CURRENT_WD}/tmp/"
SAVE_DIR = f"{CURRENT_WD}/scraper/data/"
SAVE_FILE_EXT = "json"
CURRENT_PLACE_FILE = "__current_place.txt"

DEFAULT_USER_AGENT = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko)"
    " Chrome/104.0.0.0 Safari/537.36"
)
MAX_PAGE_OFFSET = 1000
MAX_RESULTS = 100

ERROR_TITLE = "PerimeterX Captcha"
ERROR_MESSAGE = "PerimeterX error, please enter another PerimeterX key."
