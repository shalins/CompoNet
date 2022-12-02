import { categories } from "./utils/octopart";
export const numbersOnlyRegex = /([-0-9.])/g;
export const metricRegex = /([yzafpnµumcdahkMGTPEZY])/g;

const getPrefix = (name: string, data: string[]) => {
  if (name.toLowerCase().includes("price")) {
    return "$";
  } else {
    return undefined;
  }
};

const getSuffix = (name: string, data: string[]) => {
  const suffix = data[0]
    ?.replace(numbersOnlyRegex, "")
    ?.replace(metricRegex, "")
    .trim();
  return suffix === "" ? undefined : suffix;
};

const standarizeUnits = (data: string[]) => {
  return data.map((val: string) => {
    let num = parseFloat(val?.match(numbersOnlyRegex)?.join("") ?? "0");
    // Convert everything to base units.
    if (val.includes("y")) {
      num *= 1e-24;
    } else if (val.includes("z")) {
      num *= 1e-21;
    } else if (val.includes("a")) {
      num *= 1e-18;
    } else if (val.includes("f")) {
      num *= 1e-15;
    } else if (val.includes("p")) {
      num *= 1e-12;
    } else if (val.includes("n")) {
      num *= 1e-9;
    } else if (val.includes("µ")) {
      num *= 1e-6;
    } else if (val.includes("m")) {
      num *= 1e-3;
    } else if (val.includes("c")) {
      num *= 1e-2;
    } else if (val.includes("d")) {
      num *= 1e-1;
    } else if (val.includes("da")) {
      num *= 1e1;
    } else if (val.includes("h")) {
      num *= 1e2;
    } else if (val.includes("k")) {
      num *= 1e3;
    } else if (val.includes("M")) {
      num *= 1e6;
    } else if (val.includes("G")) {
      num *= 1e9;
    } else if (val.includes("T")) {
      num *= 1e12;
    } else if (val.includes("P")) {
      num *= 1e15;
    } else if (val.includes("E")) {
      num *= 1e18;
    } else if (val.includes("Z")) {
      num *= 1e21;
    } else if (val.includes("Y")) {
      num *= 1e24;
    }

    return num;
  });
};

export interface Axis {
  data: Array<number>;
  prefix?: string;
  suffix?: string;
  affix?: string;
}

export interface Component {
  category: string;
  axes: Axis[];
  mpns: string[];
  manufacturerNames: string[];
}

// We want to parse the JSON response from the server and
// convert it into a format that we can then use to generate
// the various plots for the user.
//
// Data comes in the form of a JSON response, formatted as follows:
// {
//  "6331": [
//            {
//            "part_mpn": "C0805C104K5RACTU",
//            "part_manufacturer_name": "KEMET",
//            "part_spec_ripplecurrent_display_value": "0.1 mA",
//            "part_spec_capacitance_display_value": "100 nF",
//            },
//            { ... },
//          ],
//   "6332": [ ... ]
// }
export const parse = (input: { [key: string]: any }) => {
  const components: Component[] = [];

  for (const [id, attributes] of Object.entries(input)) {
    const category =
      categories.find((category) => category.id === id)?.name ?? "Undefined";
    const axes: Axis[] = [];

    // First, go through the data and get all the attribute names.
    // From the example above, we would get:
    // ["part_mpn", "part_manufacturer_name", ...]
    const attributeNames = Object.keys(attributes[0]);

    // Since we don't want to plot the manufacturer name or the mpn,
    // we store them separately.
    let mpns: string[] = [];
    let manufacturerNames: string[] = [];

    attributeNames.forEach((name) => {
      if (name === "part_mpn") {
        mpns = attributes.map((val: any) => val[name]);
      } else if (name === "part_manufacturer_name") {
        manufacturerNames = attributes.map((val: any) => val[name]);
      } else {
        // For all other attributes, we want to get the data so we can plot it.
        const axis = attributes.map((row: { [key: string]: any }) => row[name]);
        const values = standarizeUnits(axis);
        let suffix = getSuffix(name, axis);
        let prefix = getPrefix(name, axis);
        let affix = "#";
        // If we have a suffix or a prefix, use if. If we have both, prefer the suffix.
        affix = prefix ? prefix : affix;
        affix = suffix ? suffix : affix;

        axes.push({
          data: values,
          suffix: suffix,
          prefix: prefix,
          affix: affix,
        });
      }
    });

    components.push({ category, axes, mpns, manufacturerNames });
  }

  return components;
};
