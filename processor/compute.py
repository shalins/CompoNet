import re

import numpy as np
import pandas as pd
from categories import categories_map, ceramic_class, column_map, dielectric_power_fit


def add_year(df: pd.DataFrame, year: str) -> pd.DataFrame:
    """Adds a year column to the dataframe with the specified year."""
    df["year"] = year
    return df


def rename_by_year(df: pd.DataFrame, columns, year: str) -> pd.DataFrame:
    """
    Renames specified columns by appending the year and drops the original columns.
    For example: `price` becomes `price_2023`.
    """
    for col in columns:
        year_col = f"{col}_{year}"
        df[year_col] = df[col]
        df.drop(columns=[col], inplace=True)
    return df


def merge(df: pd.DataFrame, years: list) -> pd.DataFrame:
    """
    Merges rows based on 'part_mpn', resolving conflicts using the most recent year.
    Retains year-specific columns for all available years.
    """
    # Identify year-specific columns
    year_columns = {year: [col for col in df.columns if col.endswith(f"_{year}")] for year in years}

    # Aggregate these columns separately
    agg_rules = {
        col: "first" for col in df.columns if not any(col.endswith(f"_{year}") for year in years)
    }
    for year in years:
        for col in year_columns[year]:
            agg_rules[col] = "max"

    # Group by 'part_mpn', sort by 'year', and aggregate
    df.sort_values(by="year", ascending=False, inplace=True)
    merged_df = df.groupby("part_mpn", as_index=False).agg(agg_rules).reset_index()

    return merged_df


def replace_empty_none_with_na(df):
    """
    Replaces all empty strings and 'None' strings in the DataFrame with pd.NA.

    Parameters:
    df (pd.DataFrame): The DataFrame to process.

    Returns:
    pd.DataFrame: The processed DataFrame with replacements.
    """
    # Replace 'None' and empty strings with pd.NA
    df = df.replace(["None", ""], pd.NA)

    # Optional: Convert columns that are now fully NA to the most appropriate dtype
    for col in df.columns:
        if df[col].isna().all():
            df[col] = pd.to_numeric(df[col], errors="coerce")

    return df


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
        entry = str(entry).replace(" ", "")
        num = float(re.findall(r"[-+]?(?:\d+\.\d+|\d+)", entry)[0])
        unit = re.findall(r"[^\d\s.,;:!?\-+\/\(\)\[\]{}]+", entry)[0]

        if "P" in entry:
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
    category_id = int(categories_map["Ceramic Capacitors"])
    df[column_map["ceramic_class"]] = df.loc[df["part_category_id"] == category_id][
        "part_specs_dielectric_display_value"
    ].map(lambda x: ceramic_class.get(x), na_action="ignore")
    return df


def classify_dielectric(df: pd.DataFrame) -> pd.DataFrame:
    """
    Goes through the various dielectric columns and converts them to a single
    column that's most likely to be the correct dielectric.
    """

    # For ceramic capacitors, the dielectric is the ceramic class. For aluminum
    # electric, mica, and tantlum capacitors, the dielectric is the dielectric type,
    # for example, "aluminum" or "mica". For film capacitors, we use the tables from
    # https://en.wikipedia.org/wiki/Film_capacitor to classify.
    def _get_dielectric(row):
        category_id = row["part_category_id"]
        if category_id == int(categories_map["Ceramic Capacitors"]):
            return row["part_specs_dielectric_display_value"]
        elif category_id == int(categories_map["Aluminum Electrolytic Capacitors"]):
            return "aluminum"
        elif category_id == int(categories_map["Tantalum Capacitors"]):
            return "tantalum"
        elif category_id == int(categories_map["Mica Capacitors"]):
            return "mica"
        elif category_id == int(categories_map["Film Capacitors"]):
            if (
                row["part_specs_dielectricmaterial_display_value"] == "Polyester"
                or row["part_specs_dielectricmaterial_display_value"] == "PET"
            ):
                return "PET"
            elif (
                row["part_specs_dielectricmaterial_display_value"] == "Polypropylene"
                or row["part_specs_dielectricmaterial_display_value"] == "PP"
            ):
                return "PP"
            elif row["part_specs_dielectricmaterial_display_value"] == "Polyphenylene":
                return "PPS"
            elif row["part_specs_dielectricmaterial_display_value"] == "Polystyrene":
                return "PS"
            elif row["part_specs_dielectricmaterial_display_value"] == "Polyethylene":
                return "PE"

    df[column_map["dielectric"]] = df.apply(_get_dielectric, axis=1)
    return df


def process_category(df: pd.DataFrame) -> pd.DataFrame:
    """Processes the category column to have a more human-readable column name"""
    df[column_map["category"]] = df["part_category_id"]
    return df


def process_manufacturer(df: pd.DataFrame) -> pd.DataFrame:
    """Processes the manufacturer column to have a more human-readable column name"""
    df[column_map["manufacturer"]] = df["part_manufacturer_name"]
    return df


def process_mpn(df: pd.DataFrame) -> pd.DataFrame:
    """Processes the manufacturer part number column to have a more human-readable column name"""
    df[column_map["mpn"]] = df["part_mpn"]
    return df


def process_capacitance(df: pd.DataFrame) -> pd.DataFrame:
    """
    Goes through the various capacitance columns and converts them into
    a single column of capacitance in Farads.
    """

    def _get_capacitance(row):
        if row["ceramic_class"] != "C2":
            return row["part_specs_capacitance_display_value"]
        else:
            # For class 2 ceramics, the capacitance is estimated to be
            # 0.6 times the value of the capacitance in the spec sheet.
            return row["part_specs_capacitance_display_value"] * 0.6

    df[column_map["capacitance"]] = df.apply(_get_capacitance, axis=1)
    return df


def process_voltage(df: pd.DataFrame) -> pd.DataFrame:
    """
    Goes through the various voltage columns and converts them to a single
    column that's most likely to be the rated dc voltage
    """
    # Prioritize the voltage rating dc column, then the voltage rating column
    # then the voltage column. Don't use the voltage rating ac column.
    df[column_map["voltage"]] = (
        df["part_specs_voltagerating_dc__display_value"]
        .fillna(df["part_specs_voltagerating_display_value"])
        .fillna(df["part_specs_voltage_display_value"])
    )
    return df


def process_current(df: pd.DataFrame) -> pd.DataFrame:
    """
    Goes through the various current columns and converts them to a single
    column that's most likely to be the rated rms current
    """
    # Prioritize the current rating dc column, then the current rating column
    # then the current column. Don't use the current rating ac column.
    df[column_map["current"]] = df["part_specs_ripplecurrent_display_value"].fillna(
        df["part_specs_ripplecurrent_ac__display_value"]
    )
    return df


def process_esr(df: pd.DataFrame) -> pd.DataFrame:
    """
    Goes through the various ESR columns and converts them to a single
    column that's most likely to be the correct ESR
    """
    df[column_map["esr"]] = (
        df["part_specs_esr_equivalentseriesresistance__display_value"]
        .fillna(df["part_specs_resistance_display_value"])
        .fillna(df["part_specs_seriesresistance_display_value"])
    )
    return df


def process_esr_frequency(df: pd.DataFrame) -> pd.DataFrame:
    """
    Goes through the various ESR frequency columns and converts them to a single
    column that's most likely to be the correct ESR frequency. We also split the
    frequency into low (50, 60, 100, or 120 Hz) and high (switching) (>=10 kHz).
    """
    df[column_map["esr_frequency"]] = df["part_specs_testfrequency_display_value"]

    # Split the frequency into low and high
    df[column_map["esr_frequency_low"]] = df["esr_frequency"].apply(
        lambda x: x if x <= 120 else pd.NA
    )
    df[column_map["esr_frequency_high"]] = df["esr_frequency"].apply(
        lambda x: x if x >= 10000 else pd.NA
    )
    return df


def process_price(df: pd.DataFrame, years: list) -> pd.DataFrame:
    """Processes the price column for each year to have a more human-readable column name"""
    for year in years:
        if f"part_median_price_1000_converted_price_{year}" in df.columns:
            df[f"{column_map['price']}_{year}"] = df[
                f"part_median_price_1000_converted_price_{year}"
            ]
    return df


def compute_height(df: pd.DataFrame) -> pd.DataFrame:
    def _compute_height(row):
        if pd.notna(row["part_specs_diameter_display_value"]):
            # Anything with a `diameter` is considered cylindrical.
            # Then prioritize `height` over `length`.
            diameter = row["part_specs_diameter_display_value"]

            # Select the height if it exists, otherwise select the length.
            height = row["part_specs_height_display_value"]
            if pd.isna(height):
                height = row["part_specs_length_display_value"]

            # Add height and diameter as their own columns.
            row[column_map["height"]] = height
            row[column_map["diameter"]] = diameter
            return np.pi * (diameter / 2) ** 2 * height
        else:
            # If there is no diameter, then we assume it is rectangular.
            # Use `length` and `width` as the first two dimensions.
            length = row["part_specs_length_display_value"]
            width = row["part_specs_width_display_value"]

            # Then for the last dimension prioritize `height`, then
            # `thickness`, then `depth`. If there is both a `height`
            # and a `height_seated_max field`, then choose the min
            # of the two.
            height = row["part_specs_height_display_value"]
            height_seated_max = row["part_specs_height_seated_max__display_value"]
            if pd.notna(height) and pd.notna(height_seated_max):
                height = min(height, height_seated_max)
            elif pd.isna(height) and pd.notna(height_seated_max):
                height = height_seated_max
            elif pd.isna(height):
                thickness = row["part_specs_thickness_display_value"]
                height = thickness if pd.notna(thickness) else row["part_specs_depth_display_value"]

            # Add length, width, and height  as their own columns.
            row[column_map["length"]] = length
            row[column_map["width"]] = width
            row[column_map["height"]] = height
            return length * width * height

    df[column_map["volume"]] = df.apply(_compute_volume, axis=1)
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

    def _compute_volume(row):
        if pd.notna(row["part_specs_diameter_display_value"]):
            # Anything with a `diameter` is considered cylindrical.
            # Then prioritize `height` over `length`.
            diameter = row["part_specs_diameter_display_value"]

            # Select the height if it exists, otherwise select the length.
            height = row["part_specs_height_display_value"]
            if pd.isna(height):
                height = row["part_specs_length_display_value"]

            # Add height and diameter as their own columns.
            row[column_map["height"]] = height
            row[column_map["diameter"]] = diameter
            volume = np.pi * (diameter / 2) ** 2 * height
            return pd.Series(
                [volume, height, diameter, np.nan, np.nan],
                index=[
                    column_map["volume"],
                    column_map["height"],
                    column_map["diameter"],
                    column_map["length"],
                    column_map["width"],
                ],
            )
        else:
            # If there is no diameter, then we assume it is rectangular.
            # Use `length` and `width` as the first two dimensions.
            length = row["part_specs_length_display_value"]
            width = row["part_specs_width_display_value"]

            # Then for the last dimension prioritize `height`, then
            # `thickness`, then `depth`. If there is both a `height`
            # and a `height_seated_max field`, then choose the min
            # of the two.
            height = row["part_specs_height_display_value"]
            height_seated_max = row["part_specs_height_seated_max__display_value"]
            if pd.notna(height) and pd.notna(height_seated_max):
                height = min(height, height_seated_max)
            elif pd.isna(height) and pd.notna(height_seated_max):
                height = height_seated_max
            elif pd.isna(height):
                thickness = row["part_specs_thickness_display_value"]
                height = thickness if pd.notna(thickness) else row["part_specs_depth_display_value"]

            # Add length, width, and height  as their own columns.
            row[column_map["length"]] = length
            row[column_map["width"]] = width
            row[column_map["height"]] = height
            volume = length * width * height
            return pd.Series(
                [volume, height, np.nan, length, width],
                index=[
                    column_map["volume"],
                    column_map["height"],
                    column_map["diameter"],
                    column_map["length"],
                    column_map["width"],
                ],
            )

    volume_data = df.apply(_compute_volume, axis=1)
    df = pd.concat([df, volume_data], axis=1)
    return df


def compute_mass(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the mass of the component using the formula:
    D = M / V = k * V^{alpha} * C^{beta}. Once we find the value of D, we
    can compute the mass using the formula: M = D * V.
    Values of k, alpha, and beta are taken from the paper:
    https://ieeexplore.ieee.org/document/9829957
    """

    def _compute_mass(row):
        if pd.notna(row[column_map["ceramic_class"]]) and row[column_map["ceramic_class"]] in (
            "C1",
            "C2",
        ):
            ceramic_class_str = row[column_map["ceramic_class"]]
            params = dielectric_power_fit[ceramic_class_str]
            if row[column_map["voltage"]] != 0 and row[column_map["current"]] != 0:
                return (
                    params["k"]
                    * (row[column_map["voltage"]] ** params["alpha"])
                    * (row[column_map["capacitance"]] ** params["beta"])
                    * row[column_map["volume"]]
                )
        elif pd.notna(row[column_map["dielectric"]]):
            # Check if the dielectric is PP or PET. If so, use the
            # power fit equation for those materials.
            dielectric = row[column_map["dielectric"]]
            if dielectric in ("PP", "PET", "aluminum", "tantalum"):
                params = dielectric_power_fit[dielectric]
                if row[column_map["voltage"]] != 0 and row[column_map["current"]] != 0:
                    return (
                        params["k"]
                        * (row[column_map["voltage"]] ** params["alpha"])
                        * (row[column_map["capacitance"]] ** params["beta"])
                        * row[column_map["volume"]]
                    )

    df[column_map["mass"]] = df.apply(_compute_mass, axis=1)
    return df


def compute_energy(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the energy of the component using the formula:
    E = 1/2 * C * V^2.
    """

    def _compute_energy(row):
        if row[column_map["voltage"]] != 0:
            return 0.5 * row[column_map["capacitance"]] * (row[column_map["voltage"]] ** 2)

    df[column_map["energy"]] = df.apply(_compute_energy, axis=1)
    return df


def compute_rated_power(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the rated power of the component using the formula:
    P (Rated) = V (Rated) * I (RMS). Since we only have the
    RMS current for Aluminum electrolytic and Tantalum capacitors,
    we will only compute power for those components.
    """

    def _compute_power(row):
        return row[column_map["voltage"]] * row[column_map["current"]]

    df[column_map["power"]] = df.apply(_compute_power, axis=1)
    return df


def compute_volumetric_energy_density(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the volumetric energy density of the component using the formula:
    Energy density = E / V. Works for all components with a volume and energy.
    """

    def _compute_energy_density(row):
        if row[column_map["volume"]] != 0:
            return row[column_map["energy"]] / row[column_map["volume"]]

    df[column_map["volumetric_energy_density"]] = df.apply(_compute_energy_density, axis=1)
    return df


def compute_gravimetric_energy_density(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the gravimetry energy density of the component using the formula:
    Energy density = E / M. Works for all components with a mass and energy.
    """

    def _compute_energy_density(row):
        if row[column_map["mass"]] != 0:
            return row[column_map["energy"]] / row[column_map["mass"]]

    df[column_map["gravimetric_energy_density"]] = df.apply(_compute_energy_density, axis=1)
    return df


def compute_volumetric_power_density(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the volumetric power density of the component using the formula:
    Power density = P / V, where P is the rated power and V is the volume.
    """

    def _compute_power_density(row):
        if row[column_map["volume"]] != 0:
            return row[column_map["power"]] / row[column_map["volume"]]

    df[column_map["volumetric_power_density"]] = df.apply(_compute_power_density, axis=1)
    return df


def compute_gravimetric_power_density(df: pd.DataFrame) -> pd.DataFrame:
    """
    Computes the gravimetric power density of the component using the formula:
    Power density = P / M, where P is the rated power and M is the mass.
    """

    def _compute_power_density(row):
        if row[column_map["mass"]] != 0:
            return row[column_map["power"]] / row[column_map["mass"]]

    df[column_map["gravimetric_power_density"]] = df.apply(_compute_power_density, axis=1)
    return df


def compute_energy_per_cost(df: pd.DataFrame, years: list) -> pd.DataFrame:
    """
    Computes the energy per cost of the component using the formula:
    Energy per cost = E / C, where C is the median price per 1000.
    """

    def _compute_energy_per_cost(row, year):
        if row[f"{column_map['price']}_{year}"] != 0:
            return row["energy"] / row[f"{column_map['price']}_{year}"]

    for year in years:
        df[f"{column_map['energy_per_cost']}_{year}"] = df.apply(
            _compute_energy_per_cost, axis=1, args=(year,)
        )
    return df


def drop_columns(df: pd.DataFrame, cols=[]) -> pd.DataFrame:
    """Drops the specified columns from the dataframe"""
    df = df.drop(columns=cols)
    return df


def drop_all_except(df: pd.DataFrame, cols=[]) -> pd.DataFrame:
    """Drops all columns except the specified columns from the dataframe"""
    df = df[cols]
    return df
