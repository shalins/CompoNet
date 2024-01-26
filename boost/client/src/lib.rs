use js_sys::Array;
use lazy_static::lazy_static;
use serde::{Deserialize, Deserializer};
use serde_json::{from_str, Value};
use wasm_bindgen::prelude::*;
use web_sys::console;
extern crate console_error_panic_hook;

pub mod componet {
    use super::*;

    pub mod metadata {
        include!(concat!(env!("OUT_DIR"), "/componet.metadata.rs"));
    }
    pub mod graph {
        include!(concat!(env!("OUT_DIR"), "/componet.graph.rs"));
    }
    include!(concat!(env!("OUT_DIR"), "/componet.rs"));

    #[allow(dead_code)]
    fn affix_from_str<'de, D>(deserializer: D) -> Result<Option<i32>, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s: Option<i32> = Deserialize::deserialize(deserializer)?;
        match s.unwrap_or_default() {
            0 => Ok(Some(componet::Affix::Prefix as i32)),
            1 => Ok(Some(componet::Affix::Suffix as i32)),
            _ => Ok(None),
        }
    }

    #[allow(dead_code)]
    fn col_type_from_str<'de, D>(deserializer: D) -> Result<i32, D::Error>
    where
        D: Deserializer<'de>,
    {
        use componet::metadata::ColumnType;
        let s: i32 = Deserialize::deserialize(deserializer)?;

        match s {
            0 => Ok(ColumnType::Category as i32),
            1 => Ok(ColumnType::Attribute as i32),
            2 => Ok(ColumnType::Other as i32),
            _ => Err(serde::de::Error::custom("invalid column type")),
        }
    }
}
use componet::metadata;

lazy_static! {
    #[wasm_bindgen]
    #[derive(Debug)]
    pub static ref COLUMNS: Vec<metadata::DatabaseMetadata> = {
        let data: metadata::Columns = serde_json::from_str(include_str!("./metadata/columns.json")).expect("Failed to deserialize JSON");
        data.columns
    };
    #[wasm_bindgen]
    #[derive(Debug)]
    pub static ref CATEGORIES: Vec<metadata::OctopartMetadata> = {
        let data: metadata::Categories = serde_json::from_str(include_str!("./metadata/categories.json")).expect("Failed to deserialize JSON");
        data.categories
    };
    #[wasm_bindgen]
    #[derive(Debug)]
    pub static ref ATTRIBUTES: Vec<metadata::OctopartMetadata> = {
        let data: metadata::Attributes = serde_json::from_str(include_str!("./metadata/attributes.json")).expect("Failed to deserialize JSON");
        data.attributes
    };

    // List of the updated column names that include the year in their names
    // (e.g. "price" -> "price_2022", "price_2023"). We use this to make sure
    // we query for the correct column when requesting component data.
    #[wasm_bindgen]
    #[derive(Debug)]
    pub static ref COLUMNS_THAT_UPDATE_YEARLY: Vec<&'static str> = vec!["price", "energy_per_cost"];
}

#[wasm_bindgen]
pub fn set_panic_hook() {
    console_error_panic_hook::set_once();
}

#[wasm_bindgen]
pub struct QueryGenerator;

#[wasm_bindgen]
impl QueryGenerator {
    // Some of the categories are custom and not from Octopart so we need to
    // interpret them differently.
    fn interpret_category(category: &str) -> String {
        if category == "4166" {
            "category=6331 OR \
                category=6332 OR \
                category=6333 OR \
                category=6334"
                // TODO(SHALIN): Add these once we collect data for them.
                //category=6335 OR
                //category=6336"
                .to_string()
        } else if category == "-1" {
            "category=6332 AND ceramic_class='C1'".to_string()
        } else if category == "-2" {
            "category=6332 AND ceramic_class='C2'".to_string()
        } else if category == "-3" {
            "category=6333 AND dielectric='PP'".to_string()
        } else if category == "-4" {
            "category=6333 AND dielectric='PET'".to_string()
        } else {
            format!("category={}", category)
        }
    }

    fn interpret_attribute(attributes: &mut [String], year: &str) {
        attributes.iter_mut().for_each(|attr| {
            // Check if the attribute is one of the ones that updates yearly.
            // If it is, we need to append the year to the attribute name.
            if COLUMNS_THAT_UPDATE_YEARLY.contains(&attr.as_str()) {
                *attr = format!("{}_{}", attr, year);
            }
        });
    }

    pub fn generate(category: &str, year: &str, attributes: Array) -> String {
        let mut attributes = attributes
            .iter()
            .map(|s| s.as_string().unwrap_or_default())
            .collect::<Vec<String>>();
        Self::interpret_attribute(&mut attributes, year);

        let quoted_year = format!("\"{}\"", year);

        let mut query = format!("SELECT mpn, manufacturer, {}, ", quoted_year);
        let mut query_end = "".to_string();
        attributes.iter().enumerate().for_each(|(i, attr)| {
            query = format!("{}{}", query, attr);
            query_end = format!(
                "{}{}{}{}{}",
                query_end, attr, " IS NOT NULL AND ", attr, " != 'nan'"
            );
            if i != attributes.len() - 1 {
                query = format!("{}{}", query, ", ");
                query_end = format!("{}{}", query_end, " AND ");
            }
        });

        query = format!(
            "{}{}{}{}{}{}{}{}",
            query,
            " FROM public.final WHERE (",
            Self::interpret_category(category),
            " AND ",
            quoted_year,
            "='True') AND (",
            query_end,
            ");"
        );
        console::log_1(&JsValue::from_str(&format!("{:?}", query)));
        query
    }
}

#[wasm_bindgen]
pub struct QueryParser;

#[wasm_bindgen]
impl QueryParser {
    fn collect_attribute_data(category_data: &Value, attr_shortname: &str) -> Vec<String> {
        category_data
            .as_array()
            .expect("Failed to convert cateogry to array.")
            .iter()
            .map(|d| {
                d.as_object()
                    .expect("Failed to parse JSON from server response")
                    .get(&attr_shortname.to_string())
                    .expect("Failed to get attribute from JSON object")
                    .as_str()
                    .expect("Failed to convert attribute to string")
                    .to_string()
            })
            .collect()
    }

    fn interpret_attribute(attribute: &String, year: &str) -> String {
        // Check if the attribute is one of the ones that updates yearly.
        // If it is, we need to append the correct year to the attribute name.
        let attribute_basename = attribute.split('_').next().unwrap_or(attribute);
        if COLUMNS_THAT_UPDATE_YEARLY.contains(&attribute_basename) {
            // Split the attribute name into its base name and year, and then append the correct year.
            format!("{}_{}", attribute_basename, year)
        } else {
            // If the attribute does not need updating, clone it as is.
            attribute.clone()
        }
    }

    // We want to parse the JSON response from the server and
    // convert it into a format that we can then use to generate
    // the various plots for the user.
    //
    // Data comes in the form of a JSON response, formatted as follows:
    // {
    //  "6331_2023": [
    //            {
    //            "2023": "true",
    //            "part_mpn": "C0805C104K5RACTU",
    //            "part_manufacturer_name": "KEMET",
    //            "part_spec_ripplecurrent_display_value": "0.1 mA",
    //            "part_spec_capacitance_display_value": "100 nF",
    //            },
    //            { ... },
    //          ],
    //   "6332_2023": [ ... ]
    // }
    // Note that the keys are formatted as `category_year`.
    pub fn parse(result: &str, years: Array) -> String {
        let result: Value = from_str(result).expect("Failed to parse JSON from server response");
        let result = result
            .as_object()
            .expect("Failed to parse JSON from server response");
        let mut output = componet::graph::Components {
            components: Vec::new(),
        };

        console::log_1(&JsValue::from_str(&format!(
            "Parsing {} categories",
            result.len()
        )));

        let years = years
            .iter()
            .map(|s| s.as_string().expect("Failed to convert year to string"))
            .collect::<Vec<String>>();

        // If the result is empty, we return an empty string.
        if result
            .values()
            .next()
            .expect("Failed to get first value from JSON response")
            .as_array()
            .expect("Failed to convert JSON to array")
            .is_empty()
        {
            return "{}".to_string();
        }

        // Get the list of all attributes from the results.
        let attribute_shortnames = result
            .values()
            .next()
            .expect("Failed to get first value from JSON response")
            .as_array()
            .expect("Failed to convert JSON to array")
            .first()
            .expect("Failed to get first element from JSON array")
            .as_object()
            .expect("Failed to convert JSON to object")
            .keys()
            .filter(|k| k != &"mpn" && k != &"manufacturer" && !years.contains(k))
            .collect::<Vec<&String>>();

        // Go through each category and parse the data.
        for (category_id, category_data) in result.iter() {
            console::log_1(&JsValue::from_str(&format!(
                "Parsing category {}",
                category_id
            )));

            // Since category names are split into `category_year`, we need to
            // split the category ID into the category and year.
            let name = category_id.split('_');
            let category_id = name
                .clone()
                .next()
                .expect("Failed to get category ID from key");
            let year = name
                .last()
                .expect("Failed to get year from key")
                .to_string();

            // Get category name from category ID using the COLUMNS vector.
            let category_name = &COLUMNS
                .iter()
                .find(|c| c.id.unwrap_or_default().to_string() == *category_id)
                .expect("Could not find category from the given ID")
                .name;

            let mut axes: Vec<componet::graph::Axis> = Vec::new();

            let mpns = Self::collect_attribute_data(category_data, "mpn");
            let manufacturers = Self::collect_attribute_data(category_data, "manufacturer");

            // Go through each attribute and parse the data.
            attribute_shortnames.iter().for_each(|&attr_shortname| {
                let attr_shortname = Self::interpret_attribute(attr_shortname, &year);

                // Grab all data where the name of the attribute matches
                // the name of the attribute we are currently looking at.
                console::log_1(&JsValue::from_str(&format!(
                    "Looking at attribute: {}",
                    attr_shortname
                )));
                let data = category_data
                    .as_array()
                    .expect("Failed to parse JSON from server response")
                    .iter()
                    .map(|d| {
                        d.as_object()
                            .expect("Failed to parse JSON from server response")
                            .get(&attr_shortname)
                            .expect("Failed to get attribute from JSON object")
                            .as_f64()
                            .expect("Failed to convert attribute to f64")
                    })
                    .collect::<Vec<f64>>();

                let base_attr_shortname = attr_shortname
                    .trim_end_matches(&format!("{}{}", "_", &year))
                    .to_string();
                let attr_shortname =
                    if COLUMNS_THAT_UPDATE_YEARLY.contains(&base_attr_shortname.as_str()) {
                        base_attr_shortname.to_string()
                    } else {
                        attr_shortname.to_string()
                    };

                let componet::metadata::DatabaseMetadata {
                    affix,
                    unit,
                    computed,
                    ..
                } = COLUMNS
                    .iter()
                    .find(|a| a.column == *attr_shortname)
                    .expect("Could not find attribute from the given shortname");

                // Get attribute name from shortname using the COLUMNS vector.
                let attr_name = &COLUMNS
                    .iter()
                    .find(|a| a.column == *attr_shortname)
                    .expect("Could not find attribute from the given shortname")
                    .name;
                let axis = componet::graph::Axis {
                    name: attr_name.to_string(),
                    shortname: attr_shortname.to_string(),
                    data,
                    affix: *affix,
                    unit: unit.clone(),
                    computed: computed.unwrap_or(true),
                };
                axes.push(axis);
            });

            let component = componet::graph::Component {
                name: category_name.to_string(),
                year,
                axes,
                mpns,
                manufacturers,
            };
            output.components.push(component.clone());
            console::log_1(&JsValue::from_str(&format!(
                "Finished parsing category {}: {}",
                output.components.len(),
                category_name,
            )));
        }
        serde_json::to_string(&output).expect("Failed to serialize JSON")
    }
}
