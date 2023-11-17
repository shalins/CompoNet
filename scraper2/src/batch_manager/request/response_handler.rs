use std::collections::HashMap;

use serde_json::{Error, Value};

use crate::batch_manager::types::{
    AttributeBucket, AttributeBucketCombination, AttributeBucketCombinations, AttributeBuckets,
};

/// Handles the extraction of data from JSON responses.
#[derive(Default)]
pub(crate) struct ResponseHandler();

impl ResponseHandler {
    /// Constructs a new `ResponseHandler`.
    pub(crate) fn new() -> Self {
        Self::default()
    }

    /// Extracts attribute buckets from the provided JSON value.
    ///
    /// # Arguments
    /// * `json` - The JSON value containing the response data.
    /// * `attribute_bucket_display_values` - A slice of attribute display value strings to be extracted.
    ///
    /// # Returns
    /// A `Result` containing `AttributeBuckets` on success or an `Error` if extraction fails.
    pub(crate) async fn extract_attribute_buckets(
        &self,
        json: Value,
        attribute_bucket_display_values: &[String],
    ) -> Result<AttributeBuckets, Error> {
        let mut attribute_bucket_map = HashMap::new();
        if let Some(spec_aggs) = json
            .pointer("/data/search/spec_aggs")
            .and_then(|v| v.as_array())
        {
            for (attribute_bucket_display_value, attribute_data) in
                attribute_bucket_display_values.iter().zip(spec_aggs.iter())
            {
                if let Some(buckets) = attribute_data.get("buckets").and_then(|v| v.as_array()) {
                    let extracted_attribute_buckets = buckets
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
                            AttributeBucket {
                                component_count: count,
                                display_value,
                                float_value,
                            }
                        })
                        .collect();

                    attribute_bucket_map.insert(
                        attribute_bucket_display_value.to_string(),
                        extracted_attribute_buckets,
                    );
                }
            }
        }

        Ok(AttributeBuckets {
            buckets: attribute_bucket_map,
        })
    }

    /// Extracts filter combinations from the JSON response based on given attribute IDs.
    ///
    /// # Arguments
    /// * `json` - The JSON value containing the response data.
    /// * `current_attribute_bucket_combinations` - A hashmap of bucket attribute IDs to the corresponding `AttributeBucket`.
    /// * `last_attribute_bucket_key` - The key of the last attribute bucket in the combination.
    ///
    /// # Returns
    /// A `Result` containing `AttributeBucketCombination` on success or an `Error` if extraction fails.
    pub(crate) async fn extract_attribute_bucket_combinations(
        &self,
        json: Value,
        current_attribute_bucket_combinations: HashMap<String, AttributeBucket>,
        last_attribute_bucket_key: String,
    ) -> Result<AttributeBucketCombinations, Error> {
        let mut attribute_bucket_combinations = AttributeBucketCombinations::default();
        if let Some(spec_aggs) = json
            .pointer("/data/search/spec_aggs/0/buckets")
            .and_then(|v| v.as_array())
        {
            for attribute_bucket in spec_aggs.iter() {
                let mut current_attribute_bucket_combinations =
                    current_attribute_bucket_combinations.clone();
                current_attribute_bucket_combinations.insert(
                    last_attribute_bucket_key.clone(),
                    AttributeBucket {
                        component_count: attribute_bucket
                            .get("count")
                            .and_then(|v| v.as_u64())
                            .unwrap_or(0) as usize,
                        display_value: attribute_bucket
                            .get("display_value")
                            .and_then(|v| v.as_str())
                            .unwrap_or("")
                            .to_string(),
                        float_value: attribute_bucket
                            .get("float_value")
                            .and_then(|v| v.as_f64())
                            .map(|v| v.to_string()),
                    },
                );
                let filter_combination = AttributeBucketCombination {
                    attribute_bucket_combination: current_attribute_bucket_combinations,
                    component_count: attribute_bucket
                        .get("count")
                        .and_then(|v| v.as_u64())
                        .unwrap_or(0) as usize,
                };
                attribute_bucket_combinations
                    .combinations
                    .push(filter_combination);
            }
        }
        Ok(attribute_bucket_combinations)
    }

    /// Extracts a list of components from the JSON response.
    ///
    /// # Arguments
    /// * `json` - The JSON value containing the response data.
    ///
    /// # Returns
    /// A `Result` containing a `Vec<Value>` representing components on success, or an `anyhow::Error` if no results are found.
    pub(crate) async fn extract_components(
        &self,
        json: Value,
    ) -> Result<Vec<Value>, anyhow::Error> {
        match json
            .pointer("/data/search/results")
            .and_then(|v| v.as_array())
        {
            Some(results) => Ok(results.clone()),
            None => Err(anyhow::Error::msg("No results found")),
        }
    }
}

// we want some kind of indication of how many components there are for each attribute bucket.
