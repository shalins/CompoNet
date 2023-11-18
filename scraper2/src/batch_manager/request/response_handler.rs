use std::collections::HashMap;

use anyhow::Result;
use serde_json::{Error, Value};
use tokio::sync::{oneshot, Mutex};

use crate::batch_manager::types::{
    AttributeBucket, AttributeBucketCombination, AttributeBucketCombinations, AttributeBuckets,
};

/// Handles the extraction of data from JSON responses.
pub(crate) struct ResponseHandler {
    metadata_channel_tx: Mutex<Option<oneshot::Sender<Value>>>,
    pub metadata_channel_rx: Mutex<Option<oneshot::Receiver<Value>>>,
}

impl ResponseHandler {
    /// Constructs a new `ResponseHandler`.
    pub(crate) fn new() -> Self {
        let (metadata_channel_tx, metadata_channel_rx) = oneshot::channel();
        ResponseHandler {
            metadata_channel_tx: Mutex::new(Some(metadata_channel_tx)),
            metadata_channel_rx: Mutex::new(Some(metadata_channel_rx)),
        }
    }

    pub(crate) async fn take_receiver(&self) -> Option<oneshot::Receiver<Value>> {
        self.metadata_channel_rx.lock().await.take()
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

    /// Extracts components from JSON response and sends metadata once.
    ///
    /// Sends metadata over a one-time channel, then extracts and returns components
    /// from the JSON response. If the channel is already used, metadata sending is skipped.
    ///
    /// # Arguments
    /// * `json` - JSON with response data.
    ///
    /// # Returns
    /// `Vec<Value>` of components on success, or `anyhow::Error` on failure.
    pub(crate) async fn extract_components(&self, json: Value) -> Result<Vec<Value>> {
        let metadata = self.get_component_response_metadata(json.clone()).await?;
        if let Some(sender) = self.metadata_channel_tx.lock().await.take() {
            sender.send(metadata).map_err(|_| {
                anyhow::Error::msg("Failed to send component response metadata over channel")
            })?;
        };

        match json
            .pointer("/data/search/results")
            .and_then(|v| v.as_array())
        {
            Some(results) => Ok(results.clone()),
            None => Err(anyhow::Error::msg("No results found")),
        }
    }

    /// Extracts metadata from JSON response, removing component data.
    ///
    /// Modifies JSON to remove data at `/data/search/results`, extracting metadata.
    /// Ensures the path exists before removal.
    ///
    /// # Arguments
    /// * `json` - Mutable JSON with response data.
    ///
    /// # Returns
    /// Modified JSON as `Value` on success, or `anyhow::Error` if path not found.
    async fn get_component_response_metadata(&self, mut json: Value) -> Result<Value> {
        if let Some(results) = json.pointer_mut("/data/search/results") {
            *results = Value::Array(vec![]);
        } else {
            return Err(anyhow::Error::msg(
                "Invalid JSON structure: '/data/search/results' path not found",
            ));
        }
        Ok(json)
    }
}
