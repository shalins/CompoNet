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
