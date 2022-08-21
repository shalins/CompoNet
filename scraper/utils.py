import json
import os
import pickle

from constants import CURRENT_PLACE_FILE, SAVE_DIR, SAVE_FILE_EXT


def get_query_name(query):
    """Returns the name of the query from the Graph QL string."""
    import re

    return re.search(r"\w+(?=(\s*)?\()", query).group()


def _extend_existing_json(new_data, filename):
    with open(filename, "r+") as file:
        # First we load existing data into a dict.
        file_data = json.load(file)
        # Join new_data with file_data inside emp_details
        file_data["data"]["search"]["results"].extend(new_data)
        # Sets file's current position at offset.
        file.seek(0)
        # convert back to json.
        json.dump(file_data, file)


def save_data(data, filename, intermediate=False):
    os.makedirs(SAVE_DIR, exist_ok=True)
    inter_path = f"{SAVE_DIR}{filename} Intermediate.{SAVE_FILE_EXT}"
    final_path = f"{SAVE_DIR}{filename}.{SAVE_FILE_EXT}"
    if intermediate:
        # if the file exists, then extend the data with the new data
        # otherwise, just write the data
        if os.path.exists(inter_path):
            _extend_existing_json(data["data"]["search"]["results"], inter_path)
        else:
            with open(inter_path, "w") as outfile:
                json.dump(data, outfile)
        return inter_path
    else:
        # if the intermediate file exists, then extend the data with the new data
        # otherwise, just write the data
        if os.path.exists(inter_path):
            _extend_existing_json(data["data"]["search"]["results"], inter_path)
            os.rename(inter_path, final_path)
        else:
            with open(final_path, "w") as outfile:
                json.dump(data, outfile)
        return final_path


def remove_current_place():
    if os.path.exists(f"{SAVE_DIR}{CURRENT_PLACE_FILE}"):
        os.remove(f"{SAVE_DIR}{CURRENT_PLACE_FILE}")


def save_current_place(data):
    os.makedirs(SAVE_DIR, exist_ok=True)
    with open(f"{SAVE_DIR}{CURRENT_PLACE_FILE}", "wb") as outfile:
        pickle.dump(data, outfile)


def load_current_place():
    try:
        with open(f"{SAVE_DIR}{CURRENT_PLACE_FILE}", "rb") as infile:
            return pickle.load(infile)
    except FileNotFoundError:
        return None


class Colors:  # You may need to change color settings
    RED = "\033[31m"
    ENDC = "\033[m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    PURPLE = "\033[35m"
    LIGHT_BLUE = "\033[94m"
    MAGENTA = "\033[0;95m"
    CYAN = "\033[0;96m"
    BOLD = "\033[1m"
