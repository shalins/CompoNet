use serde_json::{Error, Value};
use std::collections::HashMap;

#[derive(Clone, Debug)]
pub struct Filter {
    pub display_id: String,
    pub bucket_value: String,
}

#[derive(Clone, Debug)]
pub struct PartitionedCombination {
    pub filters: Vec<Filter>,
    pub start: usize,
    pub end: usize,
}

#[derive(Clone, Debug)]
pub struct PartitionedCombinations {
    pub partitions: Vec<PartitionedCombination>,
}

#[derive(Clone, Debug)]
pub struct BucketPair {
    pub first: Option<(String, Bucket)>,
    pub second: (String, Bucket),
}

#[derive(Debug, Clone)]
pub struct Bucket {
    pub count: usize,
    pub display_value: String,
    pub float_value: Option<String>,
}

#[derive(Debug)]
pub struct AttributeBuckets {
    pub buckets: HashMap<String, Vec<Bucket>>,
}

#[derive(Debug, Default)]
pub struct FilterCombination {
    pub combination: HashMap<String, String>,
    pub count: usize,
}

#[derive(Debug, Default)]
pub struct FilterCombinations {
    pub combinations: Vec<FilterCombination>,
}

#[derive(Default)]
pub struct ResponseHandler();

impl ResponseHandler {
    pub fn new() -> Self {
        Self {}
    }

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
