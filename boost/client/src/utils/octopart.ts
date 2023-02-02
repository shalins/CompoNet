import properties from "../json/properties.json";
import categories from "../json/categories.json";
import attributes from "../json/attributes.json";

export enum Affix {
  Prefix,
  Suffix,
}

export enum ColumnType {
  Category,
  Attribute,
  Other,
}

export interface DatabaseMetadata {
  name: string;
  column: string;
  type: ColumnType;
  unit?: string | null;
  affix?: Affix | null;
  // TODO(SHALIN): Remove string type.
  octopartId?: number | string | null;
}

// Import and parse the `properties.json` file to create the `DatabaseMetadata` object.
export const columns: DatabaseMetadata[] = properties.properties.map(
  (property) => {
    const { name, column, type, unit, affix, octopartId } = property;
    return {
      name,
      column,
      type: getColumnType(type),
      unit: nullToUndefined(unit),
      affix: getAffix(nullToUndefined(affix)),
      octopartId: nullToUndefined(octopartId),
    };
  }
);

function nullToUndefined<T>(value: T | null): T | undefined {
  return value === null ? undefined : value;
}

function getAffix(affix?: string): Affix | undefined {
  if (!affix) {
    return undefined;
  }
  switch (affix) {
    case "prefix":
      return Affix.Prefix;
    case "suffix":
      return Affix.Suffix;
    default:
      throw new Error(`Invalid affix: ${affix}`);
  }
}

function getColumnType(type: string): ColumnType {
  switch (type) {
    case "category":
      return ColumnType.Category;
    case "attribute":
      return ColumnType.Attribute;
    case "other":
      return ColumnType.Other;
    default:
      throw new Error(`Invalid column type: ${type}`);
  }
}

export interface OctopartMetadata {
  id: number;
  name: string;
  shortname?: string | null;
  units?: string | null;
}

export const _categories: OctopartMetadata[] = categories.categories.map(
  (category) => {
    const { id, name, shortname } = category;
    return {
      id,
      name,
      shortname: nullToUndefined(shortname),
    };
  }
);

export const _attributes: OctopartMetadata[] = attributes.attributes.map(
  (attribute) => {
    const { id, name, shortname } = attribute;
    return {
      id,
      name,
      shortname: nullToUndefined(shortname),
    };
  }
);

export const _columns: DatabaseMetadata[] = [
  // These are the categories that we want to display in the graph.
  // https://octopart.com/api/v4/values#categories
  //
  // We also want to include custom categories that allow for more
  // granular comparison of data.
  {
    name: "Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "4166",
  },
  {
    name: "Inductors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "4190",
  },
  {
    name: "Aluminum Electrolytic Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "6331",
  },
  {
    name: "Ceramic Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "6332",
  },
  {
    name: "Film Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "6333",
  },
  {
    name: "Mica Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "6334",
  },
  {
    name: "Polymer Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "6335",
  },
  {
    name: "Tantalum Capacitors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "6336",
  },
  {
    name: "Variable Inductors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "4191",
  },
  {
    name: "Fixed Inductors",
    column: "category",
    type: ColumnType.Category,
    octopartId: "4193",
  },
  {
    name: "Transformers",
    column: "category",
    type: ColumnType.Category,
    octopartId: "4194",
  },

  // These are the attributes that we want to display in the graph.
  // https://octopart.com/api/v4/values#attributes
  {
    name: "Dielectric",
    column: "dielectric",
    type: ColumnType.Attribute,
    unit: "n/a",
    affix: Affix.Suffix,
  },
  {
    name: "Price",
    column: "price",
    type: ColumnType.Attribute,
    unit: "$",
    affix: Affix.Prefix,
  },
  {
    name: "Capacitance",
    column: "capacitance",
    type: ColumnType.Attribute,
    unit: "F",
    affix: Affix.Suffix,
  },
  {
    name: "Current",
    column: "current",
    type: ColumnType.Attribute,
    unit: "A",
    affix: Affix.Suffix,
  },
  {
    name: "Voltage",
    column: "voltage",
    type: ColumnType.Attribute,
    unit: "V",
    affix: Affix.Suffix,
  },
  {
    name: "Volume",
    column: "volume",
    type: ColumnType.Attribute,
    unit: "mm^3",
    affix: Affix.Suffix,
  },
  {
    name: "ESR",
    column: "esr",
    type: ColumnType.Attribute,
    unit: "Ω",
    affix: Affix.Suffix,
  },
  {
    name: "ESR Frequency",
    column: "esr_frequency",
    type: ColumnType.Attribute,
    unit: "Hz",
    affix: Affix.Suffix,
  },
  {
    name: "Mass",
    column: "mass",
    type: ColumnType.Attribute,
    unit: "mg",
    affix: Affix.Suffix,
  },
  {
    name: "Energy",
    column: "energy",
    type: ColumnType.Attribute,
    unit: "μJ",
    affix: Affix.Suffix,
  },
  {
    name: "Power",
    column: "power",
    type: ColumnType.Attribute,
    unit: "W",
    affix: Affix.Suffix,
  },
  {
    name: "Volumetric Energy Denisty",
    column: "volumetric_energy_density",
    type: ColumnType.Attribute,
    unit: "μJ/mm^3",
    affix: Affix.Suffix,
  },
  {
    name: "Gravimetric Energy Density",
    column: "gravimetric_energy_density",
    type: ColumnType.Attribute,
    unit: "μJ/mg",
    affix: Affix.Suffix,
  },
  {
    name: "Volumetric Power Density",
    column: "volumetric_power_density",
    type: ColumnType.Attribute,
    unit: "W/mm^3",
    affix: Affix.Suffix,
  },
  {
    name: "Gravimetric Power Density",
    column: "gravimetric_power_density",
    type: ColumnType.Attribute,
    unit: "W/mg",
    affix: Affix.Suffix,
  },
  {
    name: "Energy Per Cost",
    column: "energy_per_cost",
    type: ColumnType.Attribute,
    unit: "μJ/$",
    affix: Affix.Suffix,
  },
];

// Contains the metadata for the Octopart component and attributes spec IDs to the corresponding display values and shortnames.
export interface _OctopartMetadata {
  id: string;
  name: string;
  shortname?: string;
  units?: string;
}

// https://octopart.com/api/v4/values#categories
export const __categories: _OctopartMetadata[] = [
  { id: "4165", name: "Passive Components" },
  { id: "4166", name: "Capacitors" },
  { id: "6331", name: "Aluminum Electrolytic Capacitors" },
  { id: "4169", name: "Capacitor Arrays" },
  { id: "4172", name: "Capacitor Kits" },
  { id: "6332", name: "Ceramic Capacitors" },
  { id: "6333", name: "Film Capacitors" },
  { id: "6334", name: "Mica Capacitors" },
  { id: "6335", name: "Polymer Capacitors" },
  { id: "6336", name: "Tantalum Capacitors" },
  { id: "4168", name: "Trimmer / Variable Capacitors" },
  { id: "4190", name: "Inductors" },
  { id: "4193", name: "Fixed Inductors" },
  { id: "6259", name: "Inductor Kits" },
  { id: "4191", name: "Variable Inductors" },
  { id: "4197", name: "Transformers" },
];

// https://octopart.com/api/v4/values#attributes
export const __attributes: _OctopartMetadata[] = [
  // Custom attributes.
  //
  // We include custom types so we can fetch them from the database
  // even if they're not officially documented attributes, i.e. computed
  // attributes like volume. To avoid conflicts with Octopart attribute IDs,
  // we make custom IDs negative.
  {
    id: "-1",
    name: "Price",
    shortname: "part_median_price_1000_converted_price",
  },

  // Octopart attributes.
  { id: "548", shortname: "capacitance", name: "Capacitance" },
  { id: "842", shortname: "case_package", name: "Case/Package" },
  { id: "384", shortname: "contactplating", name: "Contact Plating" },
  { id: "418", shortname: "diameter", name: "Diameter" },
  { id: "834", shortname: "dielectricmaterial", name: "Dielectric Material" },
  { id: "389", shortname: "dissipationfactor", name: "Dissipation Factor" },
  {
    id: "308",
    shortname: "esr_equivalentseriesresistance_",
    name: "ESR (Equivalent Series Resistance)",
  },
  { id: "587", shortname: "features", name: "Features" },
  { id: "468", shortname: "height", name: "Height" },
  { id: "386", shortname: "height_seated_max_", name: "Height - Seated (Max)" },
  { id: "539", shortname: "holediameter", name: "Hole Diameter" },
  { id: "495", shortname: "impedance", name: "Impedance" },
  { id: "473", shortname: "leaddiameter", name: "Lead Diameter" },
  { id: "724", shortname: "leadfree", name: "Lead Free" },
  { id: "545", shortname: "leadlength", name: "Lead Length" },
  { id: "285", shortname: "leadpitch", name: "Lead Pitch" },
  { id: "852", shortname: "lead_basestyle", name: "Lead/Base Style" },
  { id: "434", shortname: "leakagecurrent", name: "Leakage Current" },
  { id: "755", shortname: "length", name: "Length" },
  { id: "839", shortname: "life_hours_", name: "Life (Hours)" },
  { id: "910", shortname: "lifecyclestatus", name: "Lifecycle Status" },
  { id: "354", shortname: "material", name: "Material" },
  {
    id: "849",
    shortname: "maxoperatingtemperature",
    name: "Max Operating Temperature",
  },
  {
    id: "456",
    shortname: "minoperatingtemperature",
    name: "Min Operating Temperature",
  },
  { id: "773", shortname: "mount", name: "Mount" },
  { id: "329", shortname: "numberofpins", name: "Number of Pins" },
  { id: "412", shortname: "packaging", name: "Packaging" },
  { id: "597", shortname: "polarity", name: "Polarity" },
  { id: "683", shortname: "reachsvhc", name: "REACH SVHC" },
  { id: "634", shortname: "radiationhardening", name: "Radiation Hardening" },
  { id: "440", shortname: "resistance", name: "Resistance" },
  { id: "521", shortname: "ripplecurrent", name: "Ripple Current" },
  { id: "770", shortname: "ripplecurrent_ac_", name: "Ripple Current (AC)" },
  { id: "610", shortname: "rohs", name: "RoHS" },
  { id: "973", shortname: "scheduleB", name: "Schedule B" },
  { id: "717", shortname: "termination", name: "Termination" },
  { id: "684", shortname: "testfrequency", name: "Test Frequency" },
  { id: "342", shortname: "tolerance", name: "Tolerance" },
  { id: "324", shortname: "voltage", name: "Voltage" },
  { id: "457", shortname: "voltagerating", name: "Voltage Rating" },
  { id: "340", shortname: "voltagerating_ac_", name: "Voltage Rating (AC)" },
  { id: "323", shortname: "voltagerating_dc_", name: "Voltage Rating (DC)" },
  { id: "547", shortname: "weight", name: "Weight" },
  { id: "576", shortname: "width", name: "Width" },
  { id: "572", shortname: "casecode_imperial_", name: "Case Code (Imperial)" },
  { id: "769", shortname: "casecode_metric_", name: "Case Code (Metric)" },
  { id: "371", shortname: "composition", name: "Composition" },
  { id: "291", shortname: "depth", name: "Depth" },
  { id: "357", shortname: "dielectric", name: "Dielectric" },
  {
    id: "942",
    shortname: "manufacturerlifecyclestatus",
    name: "Manufacturer Lifecycle Status",
  },
  { id: "559", shortname: "ratings", name: "Ratings" },
  {
    id: "321",
    shortname: "temperaturecoefficient",
    name: "Temperature Coefficient",
  },
  { id: "286", shortname: "thickness", name: "Thickness" },
  { id: "478", shortname: "militarystandard", name: "Military Standard" },
  { id: "392", shortname: "corematerial", name: "Core Material" },
  { id: "638", shortname: "currentrating", name: "Current Rating" },
  { id: "201", shortname: "dcresistance_dcr_", name: "DC Resistance (DCR)" },
  { id: "233", shortname: "failurerate", name: "Failure Rate" },
  { id: "505", shortname: "frequency", name: "Frequency" },
  { id: "223", shortname: "frequencystability", name: "Frequency Stability" },
  { id: "375", shortname: "inductance", name: "Inductance" },
  { id: "359", shortname: "maxdccurrent", name: "Max DC Current" },
  {
    id: "905",
    shortname: "maxjunctiontemperature",
    name: "Max Junction Temperature (Tj)",
  },
  {
    id: "663",
    shortname: "maxpowerdissipation",
    name: "Max Power Dissipation",
  },
  { id: "588", shortname: "maxsupplyvoltage", name: "Max Supply Voltage" },
  { id: "339", shortname: "minsupplyvoltage", name: "Min Supply Voltage" },
  {
    id: "422",
    shortname: "nominalsupplycurrent",
    name: "Nominal Supply Current",
  },
  {
    id: "670",
    shortname: "nominalsupplyvoltage_dc_",
    name: "Nominal Supply Voltage (DC)",
  },
  {
    id: "784",
    shortname: "numberofterminations",
    name: "Number of Terminations",
  },
  {
    id: "637",
    shortname: "operatingsupplyvoltage",
    name: "Operating Supply Voltage",
  },
  { id: "257", shortname: "powerrating", name: "Power Rating" },
  {
    id: "230",
    shortname: "selfresonantfrequency",
    name: "Self Resonant Frequency",
  },
  { id: "831", shortname: "shielding", name: "Shielding" },
  {
    id: "563",
    shortname: "insulationresistance",
    name: "Insulation Resistance",
  },
  { id: "206", shortname: "type", name: "Type" },
  { id: "743", shortname: "color", name: "Color" },
  { id: "577", shortname: "qfactor", name: "Q Factor" },
  { id: "299", shortname: "current", name: "Current" },
  { id: "282", shortname: "dccurrent", name: "DC Current" },
  { id: "682", shortname: "inductancetolerance", name: "Inductance Tolerance" },
  { id: "939", shortname: "maxlength", name: "Max Length" },
  { id: "933", shortname: "maxwidth", name: "Max Width" },
  { id: "940", shortname: "minlength", name: "Min Length" },
  { id: "934", shortname: "minwidth", name: "Min Width" },
  { id: "465", shortname: "rmscurrent_irms_", name: "RMS Current (Irms)" },
  { id: "581", shortname: "saturationcurrent", name: "Saturation Current" },
  { id: "224", shortname: "seriesresistance", name: "Series Resistance" },
  { id: "687", shortname: "halogenfree", name: "Halogen Free" },
  { id: "928", shortname: "maxsatcurrent", name: "Max Saturation Current" },
  {
    id: "931",
    shortname: "maxtemprisecurrent",
    name: "Max Temperature Rise Current",
  },
  { id: "250", shortname: "connectortype", name: "Connector Type" },
];
