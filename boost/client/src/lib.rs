use js_sys::Array;
use serde_json::Value;
use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub struct QueryGenerator;

#[wasm_bindgen]
pub struct QueryParser;

#[wasm_bindgen]
impl QueryGenerator {
    pub fn generate(category: &str, attributes: Array) -> String {
        let attributes = attributes
            .iter()
            .map(|s| s.as_string().unwrap_or_default())
            .collect::<Vec<String>>();

        let mut query = "SELECT ".to_string();
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
            "{}{}{}{}{}{}",
            query, " FROM public.final WHERE category=", category, " AND ", query_end, ";"
        );
        return query;
    }
}

//impl QueryParser {
//    pub fn parse(query: &str) {
//        let mut query_json = serde_json::from_str(query).unwrap_or_default();
//    }
//}

#[wasm_bindgen]
pub fn test_function() -> String {
    return "Hello World".to_string();
}
