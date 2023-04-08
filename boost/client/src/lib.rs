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
}

#[wasm_bindgen]
pub fn set_panic_hook() {
    console_error_panic_hook::set_once();
}

#[wasm_bindgen]
pub struct QueryGenerator;

#[wasm_bindgen]
impl QueryGenerator {
    fn interpret_category(category: &str) -> String {
        if category == "4166" {
            return "category=6331 OR \
                category=6332 OR \
                category=6333 OR \
                category=6334"
                // TODO(SHALIN): Add these once we collect data for them.
                //category=6335 OR
                //category=6336"
                .to_string();
        } else if category == "-1" {
            return "category=6332 AND dielectric='C1'".to_string();
        } else if category == "-2" {
            return "category=6332 AND dielectric='C2'".to_string();
        } else if category == "-3" {
            return "category=6333 AND dielectric='PP'".to_string();
        } else if category == "-4" {
            return "category=6333 AND dielectric='PET'".to_string();
        } else {
            return format!("category={}", category);
        }
    }

    pub fn generate(category: &str, year: &str, attributes: Array) -> String {
        let attributes = attributes
            .iter()
            .map(|s| s.as_string().unwrap_or_default())
            .collect::<Vec<String>>();

        let mut query = "SELECT mpn, manufacturer, year, ".to_string();
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

        // Some of the categories are custom and not from Octopart so we need to
        // interpret them differently.

        query = format!(
            "{}{}{}{}{}{}{}{}",
            query,
            " FROM public.final WHERE (",
            Self::interpret_category(category),
            " AND year=",
            year,
            ") AND (",
            query_end,
            ");"
        );
        console::log_1(&JsValue::from_str(&format!("{:?}", query)));
        return query;
    }
}

#[wasm_bindgen]
pub struct QueryParser;

#[wasm_bindgen]
impl QueryParser {
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
    pub fn parse(result: &str) -> String {
        let result: Value = from_str(&result).expect("Failed to parse JSON from server response");
        let result = result
            .as_object()
            .expect("Failed to parse JSON from server response");
        let mut output = componet::graph::Components {
            components: Vec::new(),
        };

        // If the result is empty, we return an empty string.
        if result
            .values()
            .next()
            .unwrap()
            .as_array()
            .unwrap()
            .is_empty()
        {
            return "{}".to_string();
        }

        // Get the list of all attributes form the results.
        let attribute_shortnames = result
            .values()
            .next()
            .unwrap()
            .as_array()
            .unwrap()
            .first()
            .unwrap()
            .as_object()
            .unwrap()
            .keys()
            .filter(|k| k != &"mpn" && k != &"manufacturer" && k != &"year")
            .collect::<Vec<&String>>();

        // Go through each category and parse the data.
        for (category_id, category_data) in result.iter() {
            console::log_1(&JsValue::from_str(&format!(
                "Parsing category {}",
                category_id
            )));
            // Get category name from category ID using the COLUMNS vector.
            let category_name = &COLUMNS
                .iter()
                .find(|c| c.id.unwrap_or_default().to_string() == *category_id)
                .unwrap()
                .name;

            let mut axes: Vec<componet::graph::Axis> = Vec::new();

            let mpns = category_data
                .as_array()
                .unwrap()
                .iter()
                .map(|d| {
                    d.as_object()
                        .unwrap()
                        .get("mpn")
                        .unwrap()
                        .as_str()
                        .unwrap()
                        .to_string()
                })
                .collect::<Vec<String>>();

            let years = category_data
                .as_array()
                .unwrap()
                .iter()
                .map(|d| {
                    d.as_object()
                        .unwrap()
                        .get("year")
                        .unwrap()
                        .as_str()
                        .unwrap()
                        .to_string()
                })
                .collect::<Vec<String>>();

            let manufacturers = category_data
                .as_array()
                .unwrap()
                .iter()
                .map(|d| {
                    d.as_object()
                        .unwrap()
                        .get("manufacturer")
                        .unwrap()
                        .as_str()
                        .unwrap()
                        .to_string()
                })
                .collect::<Vec<String>>();

            // Go through each attribute and parse the data.
            attribute_shortnames.iter().for_each(|attr_shortname| {
                // Grab all data where the name of the attribute matches
                // the name of the attribute we are currently looking at.
                console::log_1(&JsValue::from_str(&format!(
                    "Looking at attribute: {}",
                    attr_shortname
                )));
                let data = category_data
                    .as_array()
                    .unwrap()
                    .iter()
                    .map(|d| {
                        d.as_object()
                            .unwrap()
                            .get(*attr_shortname)
                            .unwrap()
                            .as_f64()
                            .unwrap()
                    })
                    .collect::<Vec<f64>>();

                let componet::metadata::DatabaseMetadata {
                    affix,
                    unit,
                    computed,
                    ..
                } = COLUMNS
                    .iter()
                    .find(|a| a.column == **attr_shortname)
                    .unwrap();

                // Get attribute name from shortname using the COLUMNS vector.
                let attr_name = &COLUMNS
                    .iter()
                    .find(|a| a.column == **attr_shortname)
                    .expect("Couldnot find attribute from the given shortname")
                    .name;
                let axis = componet::graph::Axis {
                    name: attr_name.to_string(),
                    shortname: attr_shortname.to_string(),
                    data,
                    affix: affix.clone(),
                    unit: unit.clone(),
                    computed: computed.unwrap_or(true),
                };
                axes.push(axis);
                console::log_1(&JsValue::from_str(&format!(
                    "Finished looking at attribute: {}",
                    attr_name
                )));
            });

            let component = componet::graph::Component {
                name: category_name.to_string(),
                axes,
                mpns,
                manufacturers,
                years,
            };
            output.components.push(component);
            console::log_1(&JsValue::from_str(&format!(
                "Finished parsing category {}",
                category_name
            )));
        }
        serde_json::to_string(&output).unwrap()
    }
}

#[wasm_bindgen]
pub fn test_function() -> String {
    return "Hello World".to_string();
}
