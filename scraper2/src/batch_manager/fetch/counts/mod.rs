use std::collections::{HashMap, VecDeque};
use std::sync::Arc;
use std::vec;

use anyhow::{anyhow, Result};
use log::debug;
use tokio::sync::RwLock;

pub(crate) mod processor;

mod metadata;

use crate::batch_manager::fetch::tasks::TaskType;
use crate::batch_manager::request::request_sender::RequestSender;
use crate::batch_manager::request::response_handler::ResponseHandler;
use crate::batch_manager::types::{
    AttributeBucket, AttributeBucketCombination, AttributeBucketCombinations, AttributeBucketPair,
    AttributeBuckets,
};
use crate::cli::Arguments;
use crate::config::prompts::print_info_message;

use super::tasks::TaskProcessor;

use metadata::AttributeBucketMetadata;
use processor::AttributeTaskData;

pub(crate) struct ComponentCounter {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
    attribute_bucket_metadata: AttributeBucketMetadata,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
}

impl ComponentCounter {
    pub(crate) fn new(
        args: Arc<RwLock<Arguments>>,
        batch_size: usize,
        attribute_display_values: Vec<String>,
        attribute_buckets: AttributeBuckets,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Result<Self, anyhow::Error> {
        let attribute_bucket_metadata =
            AttributeBucketMetadata::new(attribute_display_values, attribute_buckets)?;

        Ok(Self {
            args,
            batch_size,
            attribute_bucket_metadata,
            request_sender,
            response_handler,
        })
    }

    pub(crate) async fn process(&mut self) -> Result<AttributeBucketCombinations, anyhow::Error> {
        let results = match self
            .attribute_bucket_metadata
            .attribute_buckets
            .buckets
            .len()
        {
            1 => {
                let attribute_buckets = self
                    .attribute_bucket_metadata
                    .attribute_buckets
                    .buckets
                    .clone()
                    .get(
                        &self
                            .attribute_bucket_metadata
                            .last_attribute_bucket_display_value,
                    )
                    .ok_or(anyhow!("Failed to get first attribute bucket"))?
                    .clone();
                let mut attribute_bucket_combinations = AttributeBucketCombinations::default();
                for attribute_bucket in attribute_buckets {
                    let mut combination = HashMap::new();
                    combination.insert(
                        self.attribute_bucket_metadata
                            .last_attribute_bucket_display_value
                            .clone(),
                        attribute_bucket.clone(),
                    );
                    attribute_bucket_combinations
                        .combinations
                        .push(AttributeBucketCombination {
                            attribute_bucket_combination: combination,
                            component_count: attribute_bucket.component_count,
                        })
                }
                Ok(vec![Ok(attribute_bucket_combinations)])
            }
            2 | 3 => {
                print_info_message("Counting component batches...", false);
                let attribute_buckets_to_process = self.get_attribute_bucket_pairs().await?;

                let task_data_queue: VecDeque<AttributeTaskData> = attribute_buckets_to_process
                    .into_iter()
                    .map(|attribute_bucket_pair| {
                        let (attribute_keys, attribute_values) = match &attribute_bucket_pair
                            .third_last_attribute_bucket
                        {
                            Some((k, v)) => (
                                vec![
                                    k.clone(),
                                    attribute_bucket_pair.second_last_attribute_bucket.0.clone(),
                                ],
                                vec![
                                    v.clone(),
                                    attribute_bucket_pair.second_last_attribute_bucket.1.clone(),
                                ],
                            ),
                            None => (
                                vec![attribute_bucket_pair.second_last_attribute_bucket.0.clone()],
                                vec![attribute_bucket_pair.second_last_attribute_bucket.1.clone()],
                            ),
                        };

                        AttributeTaskData {
                            last_attribute_bucket_key: self
                                .attribute_bucket_metadata
                                .last_attribute_bucket_display_value
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
        let mut attribute_bucket_combinations = AttributeBucketCombinations::default();
        let results = results?;
        for result in results {
            match result {
                Ok(new_combination) => {
                    attribute_bucket_combinations
                        .combinations
                        .extend(new_combination.combinations);
                }
                Err(err) => {
                    return Err(err);
                }
            }
        }

        for combination in &attribute_bucket_combinations.combinations {
            debug!(
                "Combination: {:?}, Count: {}",
                combination.attribute_bucket_combination, combination.component_count
            );
        }
        Ok(attribute_bucket_combinations)
    }

    async fn get_attribute_bucket_pairs(
        &self,
    ) -> Result<VecDeque<AttributeBucketPair>, anyhow::Error> {
        let last_attribute_bucket_display_value = &self
            .attribute_bucket_metadata
            .last_attribute_bucket_display_value;
        let second_last_attribute_bucket_display_value = self
            .attribute_bucket_metadata
            .second_last_attribute_bucket_display_value
            .as_ref()
            .ok_or(anyhow!(
                "Failed to get second last attribute bucket display value"
            ))?;

        let attribute_buckets: &HashMap<String, Vec<AttributeBucket>> =
            &self.attribute_bucket_metadata.attribute_buckets.buckets;
        let attribute_buckets_without_last_two_attributes: HashMap<_, _> = attribute_buckets
            .iter()
            .filter(|(key, _)| {
                ![
                    second_last_attribute_bucket_display_value,
                    last_attribute_bucket_display_value,
                ]
                .contains(key)
            })
            .collect();

        if attribute_buckets_without_last_two_attributes.is_empty() {
            Ok(self.create_pairs_for_single_attribute_bucket(
                attribute_buckets,
                second_last_attribute_bucket_display_value,
            ))
        } else {
            Ok(self.create_pairs_for_multiple_attribute_buckets(
                attribute_buckets,
                &attribute_buckets_without_last_two_attributes,
                second_last_attribute_bucket_display_value,
            ))
        }
    }

    fn create_pairs_for_single_attribute_bucket(
        &self,
        attribute_buckets: &HashMap<String, Vec<AttributeBucket>>,
        second_last_attribute_bucket_display_value: &String,
    ) -> VecDeque<AttributeBucketPair> {
        attribute_buckets
            .get(second_last_attribute_bucket_display_value)
            .unwrap_or(&vec![])
            .iter()
            .map(|second_last_attribute_bucket| AttributeBucketPair {
                third_last_attribute_bucket: None,
                second_last_attribute_bucket: (
                    second_last_attribute_bucket_display_value.clone(),
                    second_last_attribute_bucket.clone(),
                ),
            })
            .collect()
    }

    fn create_pairs_for_multiple_attribute_buckets(
        &self,
        attribute_buckets: &HashMap<String, Vec<AttributeBucket>>,
        attribute_buckets_without_last_two_attributes: &HashMap<&String, &Vec<AttributeBucket>>,
        second_last_attribute_bucket_display_value: &String,
    ) -> VecDeque<AttributeBucketPair> {
        let mut bucket_pairs = VecDeque::new();

        for (&third_last_attribute_bucket_display_value, &third_last_attribute_buckets) in
            attribute_buckets_without_last_two_attributes
        {
            let second_last_attribute_buckets = attribute_buckets
                .get(second_last_attribute_bucket_display_value)
                .expect("Failed to get second to last attribute's buckets");

            for third_last_attribute_bucket in third_last_attribute_buckets {
                for second_last_attribute_bucket in second_last_attribute_buckets {
                    bucket_pairs.push_back(AttributeBucketPair {
                        third_last_attribute_bucket: Some((
                            third_last_attribute_bucket_display_value.clone(),
                            third_last_attribute_bucket.clone(),
                        )),
                        second_last_attribute_bucket: (
                            second_last_attribute_bucket_display_value.clone(),
                            second_last_attribute_bucket.clone(),
                        ),
                    });
                }
            }
        }

        bucket_pairs
    }
}
