import json


def get_query_name(query):
    """Returns the name of the query from the Graph QL string."""
    import re

    return re.search(r"\w+(?=(\s*)?\()", query).group()


def save_data(data, filepath):
    with (open(filepath, "w")) as outfile:
        json.dump(data, outfile)
