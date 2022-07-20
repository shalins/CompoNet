from utils import get_query_name


def get_cookies(perimeterx_key):
    """Gets the cookies for the request.
    perimeterx_key: The perimeterx key to show we are not a bot.
    """
    cookies = {
        # For some reason this cookie is what is required in order to authenticate that we are
        # indeed a genuine user and not trigger a captcha page.
        "_px": perimeterx_key,
    }
    return cookies


def get_headers(user_agent):
    """Gets the headers for the request.
    user_agent: The user agent to use for the request.
    """
    headers = {
        "user-agent": user_agent,
    }
    return headers


def get_attribute_payload(query, category_id, attribute):
    """Creates the payload for the request for getting attributes.
    query: The GraphQL query to get a consistent data format.
    category_ids: The category ids to select the component we want.
    attributes: The attributes that we want to split into buckets.
    """
    json_data = {
        "operationName": get_query_name(query),
        "variables": {
            "attribute_names": [
                attribute,
            ],
            "currency": "USD",
            "filters": {
                "category_id": [category_id],
            },
            "in_stock_only": False,
        },
        "query": query,
    }
    return json_data


def get_parts_payload(query, category_id, start, limit, **kwargs):
    """Creates the payload for the request for getting components.
    query: The GraphQL query to get a consistent data format.
    category_ids: The category ids to select the component we want.
    kwargs: The keyword arguments for attributes used to filter the components.
        Example: `get_parts_payload(..., capacitance='100', voltagerating_ac_='12')`
    """
    json_data = {
        "operationName": get_query_name(query),
        "variables": {
            "country": "US",
            "currency": "USD",
            "filters": {
                "category_id": [
                    category_id,
                ],
            },
            "in_stock_only": False,
            "limit": limit,
            "start": start,
        },
        "query": query,
    }
    for key, value in kwargs.items():
        json_data["variables"]["filters"][key] = [value]
    return json_data
