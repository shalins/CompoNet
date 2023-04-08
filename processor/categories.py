# These are the mappings from Octopart's internal representations for
# categories and attributes to the ones we refer to in the post-processing
# code.

# https://octopart.com/api/v4/values#categories
categories_cache = {
    "Passive Components": "4165",
    "Capacitors": "4166",
    "Aluminum Electrolytic Capacitors": "6331",
    "Capacitor Arrays": "4169",
    "Capacitor Kits": "4172",
    "Ceramic Capacitors": "6332",
    "Film Capacitors": "6333",
    "Mica Capacitors": "6334",
    "Polymer Capacitors": "6335",
    "Tantalum Capacitors": "6336",
    "Trimmer / Variable Capacitors": "4168",
    "Inductors": "4190",
    "Fixed Inductors": "4193",
    "Inductor Kits": "6259",
    "Variable Inductors": "4191",
    "Transformers": "4197",
}

# https://octopart.com/api/v4/values#attributes
attributes_cache = {
    "Capacitance": "capacitance",
    "Case/Package": "case_package",
    "Contact Plating": "contactplating",
    "Diameter": "diameter",
    "Dielectric Material": "dielectricmaterial",
    "Dissipation Factor": "dissipationfactor",
    "ESR (Equivalent Series Resistance)": "esr_equivalentseriesresistance_",
    "Features": "features",
    "Height": "height",
    "Height - Seated (Max)": "height_seated_max_",
    "Hole Diameter": "holediameter",
    "Impedance": "impedance",
    "Lead Diameter": "leaddiameter",
    "Lead Free": "leadfree",
    "Lead Length": "leadlength",
    "Lead Pitch": "leadpitch",
    "Lead/Base Style": "lead_basestyle",
    "Leakage Current": "leakagecurrent",
    "Length": "length",
    "Life (Hours)": "life_hours_",
    "Lifecycle Status": "lifecyclestatus",
    "Material": "material",
    "Max Operating Temperature": "maxoperatingtemperature",
    "Min Operating Temperature": "minoperatingtemperature",
    "Mount": "mount",
    "Number of Pins": "numberofpins",
    "Packaging": "packaging",
    "Polarity": "polarity",
    "REACH SVHC": "reachsvhc",
    "Radiation Hardening": "radiationhardening",
    "Resistance": "resistance",
    "Ripple Current": "ripplecurrent",
    "Ripple Current (AC)": "ripplecurrent_ac_",
    "RoHS": "rohs",
    "Schedule B": "scheduleB",
    "Termination": "termination",
    "Test Frequency": "testfrequency",
    "Tolerance": "tolerance",
    "Voltage": "voltage",
    "Voltage Rating": "voltagerating",
    "Voltage Rating (AC)": "voltagerating_ac_",
    "Voltage Rating (DC)": "voltagerating_dc_",
    "Weight": "weight",
    "Width": "width",
    "Case Code (Imperial)": "casecode_imperial_",
    "Case Code (Metric)": "casecode_metric_",
    "Composition": "composition",
    "Depth": "depth",
    "Dielectric": "dielectric",
    "Manufacturer Lifecycle Status": "manufacturerlifecyclestatus",
    "Ratings": "ratings",
    "Temperature Coefficient": "temperaturecoefficient",
    "Thickness": "thickness",
    "Military Standard": "militarystandard",
    "Core Material": "corematerial",
    "Current Rating": "currentrating",
    "DC Resistance (DCR)": "dcresistance_dcr_",
    "Failure Rate": "failurerate",
    "Frequency": "frequency",
    "Frequency Stability": "frequencystability",
    "Inductance": "inductance",
    "Max DC Current": "maxdccurrent",
    "Max Junction Temperature (Tj)": "maxjunctiontemperature",
    "Max Power Dissipation": "maxpowerdissipation",
    "Max Supply Voltage": "maxsupplyvoltage",
    "Min Supply Voltage": "minsupplyvoltage",
    "Nominal Supply Current": "nominalsupplycurrent",
    "Nominal Supply Voltage (DC)": "nominalsupplyvoltage_dc_",
    "Number of Terminations": "numberofterminations",
    "Operating Supply Voltage": "operatingsupplyvoltage",
    "Power Rating": "powerrating",
    "Self Resonant Frequency": "selfresonantfrequency",
    "Shielding": "shielding",
    "Insulation Resistance": "insulationresistance",
    "Type": "type",
    "Color": "color",
    "Q Factor": "qfactor",
    "Current": "current",
    "DC Current": "dccurrent",
    "Inductance Tolerance": "inductancetolerance",
    "Max Length": "maxlength",
    "Max Width": "maxwidth",
    "Min Length": "minlength",
    "Min Width": "minwidth",
    "RMS Current (Irms)": "rmscurrent_irms_",
    "Saturation Current": "saturationcurrent",
    "Series Resistance": "seriesresistance",
    "Halogen Free": "halogenfree",
    "Max Saturation Current": "maxsatcurrent",
    "Max Temperature Rise Current": "maxtemprisecurrent",
    "Connector Type": "connectortype",
}

dielectric_power_fit = {
    "C1": {
        "k": 11.67,
        "alpha": 0.05585,
        "beta": 0.0665,
    },
    "C2": {
        "k": 8.406,
        "alpha": -0.0045,
        "beta": 0.0272,
    },
    "PET": {
        "k": 1.175,
        "alpha": -0.0212,
        "beta": -0.0167,
    },
    "PP": {
        "k": 0.934,
        "alpha": -0.0207,
        "beta": -0.0250,
    },
    # In the paper, this is listed as "Through-hole Al-Elec".
    "aluminum": {
        "k": 1.296,
        "alpha": -0.0732,
        "beta": -0.0434,
    },
    # In the paper, this is listed as "Molded Tantalum".
    "tantalum": {
        "k": 4.928,
        "alpha": 0.0482,
        "beta": 0.049,
    },
}

ceramic_class = {
    "A": "C1",
    "B": "C2",
    "BD": "C2",
    "BG": "C1",
    "BJ": "C2",
    "BL": "C2",
    "BN": "C2",
    "BP": "C1",
    "BR": "C2",
    "BV": "C3",
    "BX": "C2",
    "C": "C2",
    "C0G": "C1",
    "C0G, NP0 (1B)": "C1",
    "C0G, NP0": "C1",
    "C0H": "C1",
    "C0J": "C1",
    "C0K": "C1",
    "CCG": "C1",
    "CD": "C2",
    "CF": "C2",
    "CH": "C1",
    "CL": "C1",
    "D": "C3",
    # For Kyocera it's C1
    "E": "C3",
    "F": "C3",
    "GBBL": "C2",
    # "H3M": nan,
    "JB": "C2",
    "K2000": "C1",
    "K4000": "C1",
    # For Johanson it's C1
    "L": "C3",
    "M": "C1",
    "M3K": "C1",
    "N": "C1",
    "N1500": "C1",
    "N2000": "C1",
    "N2200": "C1",
    "N2500": "C1",
    "N2800": "C1",
    "N4700": "C1",
    "N750": "C1",
    "NP0": "C1",
    "NS": "C1",
    "P100": "C1",
    "P2G": "C1",
    "P2H": "C1",
    "P3K": "C1",
    "P90": "C1",
    "R": "C3",
    "R16": "C1",
    "R230": "C1",
    "R2H": "C1",
    "R3A": "C1",
    "R3L": "C1",
    "R42": "C1",
    "R7": "C1",
    "R85": "C1",
    "S2H": "C1",
    # "S3B": nan,
    "S3L": "C1",
    "S3N": "C1",
    "SL": "C1",
    "SL/GP": "C1",
    "T": "C2",
    "T2H": "C1",
    "U2J": "C1",
    "U2K": "C1",
    "U2M": "C1",
    # "UNJ": "nan",
    # "UX": nan,
    "X0U": "C2",
    "X5E": "C2",
    "X5F": "C2",
    "X5P": "C2",
    "X5R": "C2",
    "X5S": "C2",
    "X5U": "C3",
    "X5V": "C3",
    "X6S": "C2",
    "X6T": "C3",
    "X7R (2R1)": "C2",
    "X7R (VHT)": "C2",
    "X7R": "C2",
    "X7S": "C2",
    "X7T": "C3",
    "X7U": "C3",
    "X8G": "C2",
    "X8L": "C2",
    "X8M": "C2",
    "X8R": "C2",
    # "XAN": nan,
    # "Y": nan,
    "Y5E": "C2",
    "Y5F": "C2",
    "Y5P (B)": "C2",
    "Y5P": "C2",
    "Y5R": "C2",
    "Y5S": "C2",
    "Y5T": "C3",
    "Y5U": "C3",
    "Y5V": "C2",
    "Y5U (E)": "C3",
    "Y5V (F)": "C2",
    "Y6P": "C2",
    "YSP": "C2",
    "Z4V": "C2",
    "Z5F": "C2",
    "Z5P": "C2",
    "Z5T": "C2",
    "Z5U": "C3",
    "Z5V": "C3",
    "Z5S": "C3",
    # "ZLM": nan,
}

units = {
    "dielectric": {
        "unit": "n/a",
        "affix": "suffix",
    },
    "price": {
        "unit": "$",
        "affix": "prefix",
    },
    "capacitance": {
        "unit": "F",
        "affix": "suffix",
    },
    "current": {
        "unit": "A",
        "affix": "suffix",
    },
    "voltage": {
        "unit": "V",
        "affix": "suffix",
    },
    "volume": {
        "unit": "mm^3",
        "affix": "suffix",
    },
    "esr": {
        "unit": "Ω",
        "affix": "suffix",
    },
    "esr_frequency": {
        "unit": "Hz",
        "affix": "suffix",
    },
    "mass": {
        "unit": "mg",
        "affix": "suffix",
    },
    "energy": {
        "unit": "μJ",
        "affix": "suffix",
    },
    "power": {
        "unit": "W",
        "affix": "suffix",
    },
    "volumetric_energy_density": {
        "unit": "μJ/mm^3",
        "affix": "suffix",
    },
    "gravimetric_energy_density": {
        "unit": "μJ/mg",
        "affix": "suffix",
    },
    "volumetric_power_density": {
        "unit": "W/mm^3",
        "affix": "suffix",
    },
    "gravimetric_power_density": {
        "unit": "W/mg",
        "affix": "suffix",
    },
    "energy_per_cost": {
        "unit": "μJ/$",
        "affix": "suffix",
    },
}

# This is the dictionary of all the column names that we want to keep
# in the final dataframe, and eventually in the database. Even if most
# of the keys are the same as the values, this still allows us to easily
# change the name of a column in the future and drop columns that are
# not in this dictionary.
column_map = {
    "category": "category",
    "manufacturer": "manufacturer",
    "mpn": "mpn",
    "ceramic_class": "ceramic_class",
    "dielectric": "dielectric",
    "capacitance": "capacitance",
    "voltage": "voltage",
    "current": "current",
    "esr": "esr",
    "esr_frequency": "esr_frequency",
    "esr_frequency_low": "esr_frequency_low",
    "esr_frequency_high": "esr_frequency_high",
    "price": "price",
    "volume": "volume",
    "mass": "mass",
    "energy": "energy",
    "power": "power",
    "volumetric_energy_density": "volumetric_energy_density",
    "gravimetric_energy_density": "gravimetric_energy_density",
    "volumetric_power_density": "volumetric_power_density",
    "gravimetric_power_density": "gravimetric_power_density",
    "energy_per_cost": "energy_per_cost",
    "year": "year",
}
