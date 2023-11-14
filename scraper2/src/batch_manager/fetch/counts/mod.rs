use std::collections::{HashMap, VecDeque};
use std::sync::Arc;
use std::vec;

use anyhow::{anyhow, Result};
use tokio::sync::RwLock;

pub mod processor;

mod metadata;

use crate::batch_manager::fetch::tasks::TaskType;
use crate::batch_manager::request::request_sender::RequestSender;
use crate::batch_manager::request::response_handler::ResponseHandler;
use crate::batch_manager::types::{
    AttributeBuckets, Bucket, BucketPair, FilterCombination, FilterCombinations,
};
use crate::cli::Arguments;

use super::tasks::TaskProcessor;

use metadata::AttributeBucketMetadata;
use processor::AttributeTaskData;

pub struct ComponentCounter {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
    attribute_bucket_metadata: AttributeBucketMetadata,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
}

impl ComponentCounter {
    pub fn new(
        args: Arc<RwLock<Arguments>>,
        batch_size: usize,
        attribute_ids: Vec<String>,
        attribute_buckets: AttributeBuckets,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Result<Self, anyhow::Error> {
        let attribute_bucket_metadata =
            AttributeBucketMetadata::new(attribute_ids, attribute_buckets)?;

        Ok(Self {
            args,
            batch_size,
            attribute_bucket_metadata,
            request_sender,
            response_handler,
        })
    }

    pub async fn process(&mut self) -> Result<FilterCombinations, anyhow::Error> {
        let results = match self
            .attribute_bucket_metadata
            .attribute_buckets
            .buckets
            .len()
        {
            1 => {
                let buckets = self
                    .attribute_bucket_metadata
                    .attribute_buckets
                    .buckets
                    .clone()
                    .get(&self.attribute_bucket_metadata.last_attribute_bucket_key)
                    .ok_or(anyhow!("Failed to get first attribute bucket"))?
                    .clone();
                let mut filter_combinations = FilterCombinations::default();
                for bucket in buckets {
                    let mut combination = HashMap::new();
                    combination.insert(
                        self.attribute_bucket_metadata
                            .last_attribute_bucket_key
                            .clone(),
                        bucket
                            .float_value
                            .unwrap_or(bucket.display_value)
                            .to_string(),
                    );
                    filter_combinations.combinations.push(FilterCombination {
                        combination,
                        count: bucket.count,
                    })
                }
                Ok(vec![Ok(filter_combinations)])
            }
            2 | 3 => {
                let buckets_to_process = self.get_bucket_pairs().await?;

                let task_data_queue: VecDeque<AttributeTaskData> = buckets_to_process
                    .into_iter()
                    .map(|bucket_pair| {
                        let (attribute_keys, attribute_values) = match &bucket_pair.first {
                            Some((k, v)) => (
                                vec![k.clone(), bucket_pair.second.0.clone()],
                                vec![v.clone(), bucket_pair.second.1.clone()],
                            ),
                            None => (
                                vec![bucket_pair.second.0.clone()],
                                vec![bucket_pair.second.1.clone()],
                            ),
                        };

                        AttributeTaskData {
                            last_attribute_bucket_key: self
                                .attribute_bucket_metadata
                                .last_attribute_bucket_key
                                .clone(),
                            attribute_keys,
                            attribute_values,
                        }
                    })
                    .collect();

                self.process_tasks(TaskType::ComponentCount, task_data_queue)
                    .await
            }
            _ => Ok(Vec::new()),
        };
        let mut all_combinations = FilterCombinations::default();
        let results = results?;
        for result in results {
            match result {
                Ok(filter_combinations) => {
                    all_combinations
                        .combinations
                        .extend(filter_combinations.combinations);
                }
                Err(err) => {
                    // Handle the error properly, maybe log it or return an error
                    return Err(err);
                }
            }
        }

        println!("All Combinations:");
        for combination in &all_combinations.combinations {
            println!(
                "  Combination: {:?}, Count: {}",
                combination.combination, combination.count
            );
        }
        Ok(all_combinations)
    }

    async fn get_bucket_pairs(&self) -> Result<VecDeque<BucketPair>, anyhow::Error> {
        let last_key = &self.attribute_bucket_metadata.last_attribute_bucket_key;
        let second_last_key = self
            .attribute_bucket_metadata
            .second_last_attribute_bucket_key
            .as_ref()
            .ok_or(anyhow!("Failed to get second last attribute bucket key"))?;

        let buckets = &self.attribute_bucket_metadata.attribute_buckets.buckets;
        let filtered_buckets: HashMap<_, _> = buckets
            .iter()
            .filter(|(key, _)| ![second_last_key, last_key].contains(key))
            .collect();

        if filtered_buckets.is_empty() {
            Ok(self.create_pairs_for_single_attribute(buckets, second_last_key))
        } else {
            Ok(self.create_pairs_for_multiple_attributes(
                buckets,
                &filtered_buckets,
                second_last_key,
            ))
        }
    }

    fn create_pairs_for_single_attribute(
        &self,
        buckets: &HashMap<String, Vec<Bucket>>,
        current_key: &String,
    ) -> VecDeque<BucketPair> {
        buckets
            .get(current_key)
            .unwrap_or(&vec![])
            .iter()
            .map(|bucket| BucketPair {
                first: None,
                second: (current_key.clone(), bucket.clone()),
            })
            .collect()
    }

    fn create_pairs_for_multiple_attributes(
        &self,
        buckets: &HashMap<String, Vec<Bucket>>,
        filtered_buckets: &HashMap<&String, &Vec<Bucket>>,
        current_key: &String,
    ) -> VecDeque<BucketPair> {
        let mut bucket_pairs = VecDeque::new();

        for (other_key, other_values) in filtered_buckets {
            let current_values = buckets
                .get(current_key)
                .expect("Failed to get current values");

            for other_value in *other_values {
                for current_value in current_values {
                    bucket_pairs.push_back(BucketPair {
                        first: Some(((*other_key).clone(), other_value.clone())),
                        second: (current_key.clone(), current_value.clone()),
                    });
                }
            }
        }

        bucket_pairs
    }
}
