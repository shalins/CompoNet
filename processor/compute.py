import math
import re

import pandas as pd
import pint
from categories import categories_cache, ceramic_class


def _convert_to_float(entry: str):
    """
    Convert a string to a float.

    entry: str
        A string representing a number with units

    Returns
    -------
    float
        The number in base SI units

    """
    try:
        entry = str(entry)
        num = float(re.findall(r"[-+]?(?:\d+\.\d+|\d+)", entry)[0])
        return num
    except:
        return entry


def _convert_to_int(entry: str):
    """
    Convert a string to an integer.

    entry: str
        A string representing a number with units

    Returns
    -------
    int
        The number in base SI units

    """
    try:
        entry = str(entry)
        num = int(re.findall(r"[-+]?(?:\d+\.\d+|\d+)", entry)[0])
        return num
    except:
        return entry


def _convert_to_base_units(entry: str):
    """
    Convert a string to a float in base SI units.

    entry: str
        A string representing a number with units

    Returns
    -------
    float
        The number in base SI units

    """
    try:
        entry = str(entry)
        num = float(re.findall(r"[-+]?(?:\d+\.\d+|\d+)", entry)[0])
        unit = re.findall(r"[a-zA-Z]+", entry)[0]

        if "Q" in entry:
            return num * 1e30
        elif "R" in entry:
            return num * 1e27
        elif "Y" in entry:
            return num * 1e24
        elif "Z" in entry:
            return num * 1e21
        elif "E" in entry:
            return num * 1e18
        elif "P" in entry:
            return num * 1e15
        elif "T" in entry:
            return num * 1e12
        elif "G" in entry:
            return num * 1e9
        elif "M" in entry:
            return num * 1e6
        elif "k" in entry:
            return num * 1e3
        elif "h" in entry:
            return num * 1e2
        elif "da" in entry:
            return num * 1e1
        elif "d" in entry:
            return num * 1e-1
        elif "c" in entry:
            return num * 1e-2
        elif "u" in entry or "µ" in entry:
            return num * 1e-6
        elif "n" in entry:
            return num * 1e-9
        elif "p" in entry:
            return num * 1e-12
        elif "f" in entry:
            return num * 1e-15
        elif "a" in entry:
            return num * 1e-18
        elif "z" in entry:
            return num * 1e-21
        elif "y" in entry:
            return num * 1e-24
        elif "r" in entry:
            return num * 1e-27
        elif "q" in entry:
            return num * 1e-30
        # Place this last to avoid matching "m" in units like "µm".
        # But avoid treating meter as a prefix.
        elif "m" in entry and len(unit) != 1:
            return num * 1e-3
        else:
            return num
    except:
        return entry


def spec_string_to_base_float(df: pd.DataFrame, cols=None) -> pd.DataFrame:
    """Converts the spec string into base units and returns as a float"""
    if cols is None:
        cols = [col for col in df.columns if "specs" in col and "display_value" in col]
    elif not isinstance(cols, list):
        cols = [cols]

    df[cols] = df[cols].applymap(_convert_to_base_units, na_action="ignore")
    return df


def spec_string_to_float(df: pd.DataFrame, cols=None) -> pd.DataFrame:
    """Converts the spec string into a float"""
    if cols is None:
        cols = [col for col in df.columns if "specs" in col and "display_value" in col]
    elif not isinstance(cols, list):
        cols = [cols]

    df[cols] = df[cols].applymap(_convert_to_float, na_action="ignore")
    return df


def spec_string_to_int(df: pd.DataFrame, cols=None) -> pd.DataFrame:
    """Converts the spec string into an integer"""
    if cols is None:
        cols = [col for col in df.columns if "specs" in col and "display_value" in col]
    elif not isinstance(cols, list):
        cols = [cols]

    df[cols] = df[cols].applymap(_convert_to_int, na_action="ignore")
    return df


def classify_ceramic(df: pd.DataFrame) -> pd.DataFrame:
    """Splits the ceramic column into two columns: class 1 and class 2 ceramic
    Uses the CSV file in the data directory as a lookup table to find which class
    each ceramic belongs to, then creates a new column identifying the class.
    """
    category_id = int(categories_cache["Ceramic Capacitors"])
    df["ceramic_class"] = df.loc[df["part_category_id"] == category_id][
        "part_specs_dielectric_display_value"
    ].map(lambda x: ceramic_class.get(x), na_action="ignore")
    return df


def compute_volume(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the volume of the part in cubic meters. For cylindrical components,
    we compute volume as pi * (d / 2)^2 * h. For rectangular components, we
    compute volume as w * l * h.

    Parameters
    ----------
    df : pd.DataFrame
        The dataframe to compute the volume for

    Returns
    -------
    pd.DataFrame
        The dataframe with the volume column added

    """
    # df["volume"] = df.apply(lambda x: (x["part_specs_diameter_display_value"].float() / 2) ** 2 * math.pi if x["part_specs_diameter_display_value"] is not None else x["part_specs_height_display_value"] * x["part_specs_width_display_value"] * x["part_specs_length_display_value"]), axis=1)

    df["volume"] = df.apply(
        lambda x: (
            math.pi
            * (x["part_specs_diameter_display_value"] / 2) ** 2
            * x["part_specs_height_display_value"]
            if x["part_specs_diameter_display_value"] and isinstance(
                x["part_specs_diameter_display_value"], float
            )
            else x["part_specs_width_display_value"]
            * x["part_specs_length_display_value"]
            * x["part_specs_height_display_value"]
        ),
        axis=1,
    )
    print(df["volume"])
    return df
