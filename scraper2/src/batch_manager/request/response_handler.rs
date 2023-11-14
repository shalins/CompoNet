use crate::batch_manager::types::{
    AttributeBuckets, Bucket, FilterCombination, FilterCombinations,
};
use serde_json::{Error, Value};
use std::collections::HashMap;

/// Handles the extraction of data from JSON responses.
#[derive(Default)]
pub struct ResponseHandler();

impl ResponseHandler {
    /// Constructs a new `ResponseHandler`.
    pub fn new() -> Self {
        Self::default()
    }

    /// Extracts attribute buckets from the provided JSON value.
    ///
    /// # Arguments
    /// * `json` - The JSON value containing the response data.
    /// * `attribute_ids` - A slice of attribute ID strings to be extracted.
    ///
    /// # Returns
    /// A `Result` containing `AttributeBuckets` on success or an `Error` if extraction fails.
    pub async fn extract_buckets(
        &self,
        json: Value,
        attribute_ids: &[String],
    ) -> Result<AttributeBuckets, Error> {
        let mut bucket_map = HashMap::new();
        if let Some(spec_aggs) = json
            .pointer("/data/search/spec_aggs")
            .and_then(|v| v.as_array())
        {
            for (name, attribute_data) in attribute_ids.iter().zip(spec_aggs.iter()) {
                if let Some(buckets) = attribute_data.get("buckets").and_then(|v| v.as_array()) {
                    let extracted_buckets = buckets
                        .iter()
                        .map(|bucket| {
                            let count =
                                bucket.get("count").and_then(|v| v.as_u64()).unwrap_or(0) as usize;
                            let display_value = bucket
                                .get("display_value")
                                .and_then(|v| v.as_str())
                                .unwrap_or("")
                                .to_string();
                            let float_value = bucket
                                .get("float_value")
                                .and_then(|v| v.as_f64())
                                .map(|v| v.to_string());
                            Bucket {
                                count,
                                display_value,
                                float_value,
                            }
                        })
                        .collect();

                    bucket_map.insert(name.to_string(), extracted_buckets);
                }
            }
        }

        Ok(AttributeBuckets {
            buckets: bucket_map,
        })
    }

    /// Extracts filter combinations from the JSON response based on given attribute IDs.
    ///
    /// # Arguments
    /// * `json` - The JSON value containing the response data.
    /// * `attribute_ids` - A hashmap of attribute IDs to their corresponding values.
    /// * `last_attribute_id` - The last attribute ID in the sequence to be processed.
    ///
    /// # Returns
    /// A `Result` containing `FilterCombinations` on success or an `Error` if extraction fails.
    pub async fn extract_filter_combinations(
        &self,
        json: Value,
        attribute_ids: HashMap<String, String>,
        last_attribute_id: String,
    ) -> Result<FilterCombinations, Error> {
        let mut filter_combinations = FilterCombinations::default();
        if let Some(spec_aggs) = json
            .pointer("/data/search/spec_aggs/0/buckets")
            .and_then(|v| v.as_array())
        {
            for bucket in spec_aggs.iter() {
                let mut attribute_ids = attribute_ids.clone();
                attribute_ids.insert(
                    last_attribute_id.clone(),
                    bucket
                        .get("float_value")
                        .and_then(|v| v.as_f64())
                        .map(|f| f.to_string())
                        .or({
                            bucket
                                .get("display_value")
                                .and_then(|v| v.as_str())
                                .map(|s| s.to_string())
                        })
                        .unwrap_or("".to_string()),
                );
                let filter_combination = FilterCombination {
                    combination: attribute_ids,
                    count: bucket.get("count").and_then(|v| v.as_u64()).unwrap_or(0) as usize,
                };
                filter_combinations.combinations.push(filter_combination);
            }
        }
        Ok(filter_combinations)
    }

    /// Extracts a list of components from the JSON response.
    ///
    /// # Arguments
    /// * `json` - The JSON value containing the response data.
    ///
    /// # Returns
    /// A `Result` containing a `Vec<Value>` representing components on success, or an `anyhow::Error` if no results are found.
    pub async fn extract_components(&self, json: Value) -> Result<Vec<Value>, anyhow::Error> {
        match json
            .pointer("/data/search/results")
            .and_then(|v| v.as_array())
        {
            Some(results) => Ok(results.clone()),
            None => {
                println!("JSON: {:?}", json);
                Err(anyhow::Error::msg("No results found"))
            }
        }
    }
}

// we want some kind of indication of how many components there are for each attribute bucket.
