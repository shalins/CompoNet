import json
import os

from constants import SAVE_FILE_EXT


def get_query_name(query):
    """Returns the name of the query from the Graph QL string."""
    import re

    return re.search(r"\w+(?=(\s*)?\()", query).group()


def save_data(data, directory, filename):
    os.makedirs(directory, exist_ok=True)
    i = 0
    while os.path.exists(f"{directory}{filename}{i}.{SAVE_FILE_EXT}"):
        i += 1
    with (open(f"{directory}{filename}{i}.{SAVE_FILE_EXT}", "w")) as outfile:
        json.dump(data, outfile)
    return f"{directory}{filename}{i}.{SAVE_FILE_EXT}"

class Colors: # You may need to change color settings
    RED = '\033[31m'
    ENDC = '\033[m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
