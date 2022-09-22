import { attributeShortnames, categoryIds } from "utils/octopart";
export const numbersOnlyRegex = /([-0-9.])/g;

const processMetric = (data: string[]) => {
  return data.map((val: string) => {
    let num = parseFloat(val?.match(numbersOnlyRegex)?.join("") ?? "0");
    // Convert everything to farads.
    if (val.includes("y")) {
      num *= 1e-24;
    } else if (val.includes("z")) {
      num *= 1e-21;
    } else if (val.includes("a")) {
      num *= 1e-18;
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
}

export interface Component {
  name: string;
  axes: Axis[];
}

const processPrice = (data: any) => {
  return data.map((item: any) => {
    let val = item.part_median_price_1000_converted_price;
    val = val.match(numbersOnlyRegex).join("");
    val = parseFloat(val);
    return val;
  });
};

export const parse = (
  input: any,
  categories: string[],
  attributes: string[]
) => {
  // We want to parse the JSON response from the server and
  // convert it into a format that we can then use to generate
  // the various plots for the user.

  // Convert the attribute names to shortnames and then to column names.
  const attributeColumns = attributes.map((name) => {
    const shortname = attributeShortnames[name];
    return `part_specs_${shortname}_display_value`;
  });

  const components: Component[] = [];

  // First go through all the categories and get the attributes.
  categories.forEach((name) => {
    const id = categoryIds[name];
    const componentData = input[id];
    // get x and y values based on the attributes.
    const axes: Axis[] = [];

    attributeColumns.forEach((column) => {
      const axis = componentData.map((item: any) => {
        return item[column];
      });
      // Process the data based on the attribute.
      const values = processMetric(axis);
      axes.push({ data: values, suffix: "F" });
    });
    components.push({ name, axes });
    //console.log(axes);
  });
  return components;
};
