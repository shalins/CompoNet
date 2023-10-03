use futures::future::join_all;
use std::collections::HashMap;
use std::sync::Arc;
use std::vec;

use anyhow::{anyhow, Result};

use crate::cli::Cli;
use crate::request_sender::{RequestSender, RequestType};
use crate::response_handler::{
    AttributeBuckets, Bucket, FilterCombination, FilterCombinations, ResponseHandler,
};

pub struct BatchManager {
    batch_size: usize,
}

impl BatchManager {
    pub fn new(batch_size: usize) -> Self {
        Self { batch_size }
    }

    async fn process_buckets_for_three_attributes(
        &self,
        second_last_key: String,
        last_key: String,
        buckets: HashMap<String, Vec<Bucket>>,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Result<Vec<Result<FilterCombinations>>> {
        let filtered_buckets: HashMap<String, Vec<Bucket>> = buckets
            .iter()
            .filter(|(key, _)| *key != &second_last_key && *key != &last_key)
            .map(|(key, value)| (key.clone(), value.clone())) // clone the keys and values
            .collect();

        let mut results = Vec::new();
        for (filtered_bucket_key, filtered_bucket_values) in filtered_buckets {
            for filtered_bucket_value in filtered_bucket_values {
                let second_last_bucket = buckets
                    .get(&second_last_key)
                    .ok_or(anyhow!("Failed to get first attribute bucket"))?
                    .clone();

                let tasks: Vec<_> = second_last_bucket
                    .into_iter()
                    .map(|bucket| {
                        let filtered_bucket_key = filtered_bucket_key.clone();
                        let filtered_bucket_value = filtered_bucket_value.clone();
                        let second_last_key = second_last_key.clone();
                        let last_key = last_key.clone();
                        let request_sender = request_sender.clone();
                        let response_handler = response_handler.clone();

                        tokio::spawn(async move {
                            let mut filters = HashMap::new();
                            filters.insert(
                                filtered_bucket_key.clone(),
                                vec![filtered_bucket_value
                                    .float_value
                                    .clone()
                                    .unwrap_or(filtered_bucket_value.display_value.clone())],
                            );
                            filters.insert(
                                second_last_key.clone(),
                                vec![bucket
                                    .float_value
                                    .clone()
                                    .unwrap_or(bucket.display_value.clone())],
                            );
                            let response = request_sender
                                .clone()
                                .send_request(RequestType::ComponentCount {
                                    attributes: Some(vec![last_key.clone()]),
                                    filters: Some(filters),
                                })
                                .await
                                .map_err(anyhow::Error::new)?;

                            let current_attributes = vec![bucket.display_value.clone()];
                            response_handler
                                .extract_filter_combinations(response, current_attributes)
                                .await
                                .map_err(anyhow::Error::new) // map error to anyhow::Error
                        })
                    })
                    .collect();

                let task_results = join_all(tasks).await.into_iter();
                let flattened_results_iter = task_results.map(|task_result| match task_result {
                    Ok(ok_value) => ok_value,
                    Err(join_error) => Err(anyhow!(join_error)),
                });

                results.extend(flattened_results_iter);
            }
        }

        Ok(results)
    }

    async fn process_buckets_for_two_attributes(
        &self,
        second_last_key: String,
        last_key: String,
        buckets: HashMap<String, Vec<Bucket>>,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Result<Vec<Result<FilterCombinations>>> {
        let second_last_bucket = buckets
            .get(&second_last_key)
            .ok_or(anyhow!("Failed to get first attribute bucket"))?
            .clone();
        let tasks: Vec<_> = second_last_bucket
            .into_iter()
            .map(|bucket| {
                let second_last_key = second_last_key.clone();
                let last_key = last_key.clone();
                let request_sender = request_sender.clone();
                let response_handler = response_handler.clone();

                tokio::spawn(async move {
                    let mut filters = HashMap::new();
                    filters.insert(
                        second_last_key.clone(),
                        vec![bucket
                            .float_value
                            .clone()
                            .unwrap_or(bucket.display_value.clone())],
                    );
                    let response = request_sender
                        .clone()
                        .send_request(RequestType::ComponentCount {
                            attributes: Some(vec![last_key.clone()]),
                            filters: Some(filters),
                        })
                        .await
                        .map_err(anyhow::Error::new)?;

                    let current_attributes = vec![bucket.display_value.clone()];
                    response_handler
                        .extract_filter_combinations(response, current_attributes)
                        .await
                        .map_err(anyhow::Error::new) // map error to anyhow::Error
                })
            })
            .collect();
        join_all(tasks)
            .await
            .into_iter()
            .map(|task| task.map_err(|e| anyhow!(e)))
            .collect()
    }

    async fn process_buckets(
        &self,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
        attribute_ids: &Vec<String>,
        attribute_buckets: AttributeBuckets,
    ) -> Result<()> {
        let results = match attribute_buckets.buckets.len() {
            1 => {
                let last_key = attribute_ids
                    .last()
                    .ok_or(anyhow!("Failed to get the last attribute key"))?
                    .clone();
                let buckets = attribute_buckets
                    .buckets
                    .clone()
                    .get(&last_key)
                    .ok_or(anyhow!("Failed to get first attribute bucket"))?
                    .clone();
                let mut combination = FilterCombinations::default();
                for bucket in buckets {
                    combination.combinations.push(FilterCombination {
                        combination: vec![bucket.display_value.to_string()],
                        count: bucket.count,
                    })
                }
                Ok(vec![Ok(combination)])
            }
            2 => {
                let second_last_key = attribute_ids[attribute_ids.len() - 2].clone();
                let last_key = attribute_ids
                    .last()
                    .ok_or(anyhow!("Failed to get the last attribute key"))?
                    .clone();
                self.process_buckets_for_two_attributes(
                    second_last_key,
                    last_key,
                    attribute_buckets.buckets,
                    request_sender,
                    response_handler,
                )
                .await
            }
            3 => {
                let second_last_key = attribute_ids[attribute_ids.len() - 2].clone();
                let last_key = attribute_ids
                    .last()
                    .ok_or(anyhow!("Failed to get the last attribute key"))?
                    .clone();
                self.process_buckets_for_three_attributes(
                    second_last_key,
                    last_key,
                    attribute_buckets.buckets,
                    request_sender,
                    response_handler,
                )
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
        Ok(())
    }

    pub async fn grab_component_count(&self) -> Result<()> {
        let cli = Cli::new();
        let args = cli.get_args();
        let request_sender = Arc::new(RequestSender::new(args));
        let response_handler = Arc::new(ResponseHandler::new());

        // 1. Get the attribute ids from the request sender.
        let attribute_ids = request_sender
            .get_attribute_ids()
            .ok_or_else(|| anyhow!("Failed to get attribute ids"))?;

        // 2. Send a request to get the buckets for all the attributes.
        let attribute_response = request_sender
            .clone()
            .send_request(RequestType::Attributes)
            .await
            .map_err(anyhow::Error::new)?;

        // 3. Join the attribute ids with the buckets from the response.
        let attribute_buckets = response_handler
            .clone()
            .extract_buckets(attribute_response, attribute_ids)
            .await
            .map_err(anyhow::Error::new)?;

        self.process_buckets(
            request_sender.clone(),
            response_handler.clone(),
            attribute_ids,
            attribute_buckets,
        )
        .await?;
        Ok(())

        // match attribute_buckets.buckets.len() {
        //     1 => {
        //         let first_attribute_key = attribute_ids
        //             .get(0)
        //             .ok_or(anyhow!("Failed to get first attribute key"))?
        //             .clone();
        //         let buckets = attribute_buckets
        //             .buckets
        //             .clone()
        //             .get(&first_attribute_key)
        //             .ok_or(anyhow!("Failed to get first attribute bucket"))?
        //             .clone();
        //         let mut combination = FilterCombinations::default();
        //         for bucket in buckets {
        //             combination.combinations.push(FilterCombination {
        //                 combination: vec![bucket.display_value.to_string()],
        //                 count: bucket.count,
        //             })
        //         }
        //         Ok(())
        //     }
        //     2 => {
        //         let buckets = attribute_buckets.buckets.clone();
        //         let first_attribute_key = attribute_ids
        //             .get(0)
        //             .ok_or(anyhow!("Failed to get first attribute key"))?
        //             .clone();
        //         let first_attribute_bucket = buckets
        //             .get(&first_attribute_key)
        //             .ok_or(anyhow!("Failed to get first attribute bucket"))?
        //             .clone();
        //         let last_attribute_key = attribute_ids
        //             .last()
        //             .cloned()
        //             .map(|key| vec![key])
        //             .ok_or_else(|| anyhow!("Failed to get last attribute key"))?;

        //         let tasks: Vec<_> = first_attribute_bucket
        //             .into_iter()
        //             .map(|bucket| {
        //                 let first_attribute_key = first_attribute_key.clone();
        //                 let last_attribute_key = last_attribute_key.clone();
        //                 let request_sender = request_sender.clone();
        //                 let response_handler = response_handler.clone();

        //                 tokio::spawn(async move {
        //                     let mut filters = HashMap::new();
        //                     filters.insert(
        //                         first_attribute_key.clone(),
        //                         vec![bucket
        //                             .float_value
        //                             .clone()
        //                             .unwrap_or(bucket.display_value.clone())],
        //                     );
        //                     let response = request_sender
        //                         .clone()
        //                         .send_request(RequestType::ComponentCount {
        //                             attributes: Some(last_attribute_key.clone()),
        //                             filters: Some(filters),
        //                         })
        //                         .await
        //                         .map_err(anyhow::Error::new)?;

        //                     let current_attributes = vec![bucket.display_value.clone()];
        //                     response_handler
        //                         .extract_filter_combinations(response, current_attributes)
        //                         .await
        //                         .map_err(anyhow::Error::new) // map error to anyhow::Error
        //                 })
        //             })
        //             .collect();
        //         let results: Result<Vec<_>, _> = join_all(tasks)
        //             .await
        //             .into_iter()
        //             .map(|task| task.map_err(|e| anyhow!(e)))
        //             .collect();

        //         let results = results?; // Extract Vec if Result is Ok, return Err otherwise
        //         if results.is_empty() {
        //             return Err(anyhow!("The vector is empty")); // Using anyhow! macro for creating an error
        //         }

        //         let mut all_combinations = FilterCombinations::default();
        //         for result in results {
        //             match result {
        //                 Ok(filter_combinations) => {
        //                     all_combinations
        //                         .combinations
        //                         .extend(filter_combinations.combinations);
        //                 }
        //                 Err(err) => {
        //                     // Handle the error properly, maybe log it or return an error
        //                     return Err(err);
        //                 }
        //             }
        //         }

        //         println!("All Combinations:");
        //         for combination in &all_combinations.combinations {
        //             println!(
        //                 "  Combination: {:?}, Count: {}",
        //                 combination.combination, combination.count
        //             );
        //         }
        //         Ok(())
        //     }
        //     _ => Ok(()),
        //  }
    }

    pub async fn run(&self) {
        let cli = Cli::new();
        let args = cli.get_args();
        let request_sender = Arc::new(RequestSender::new(args));

        //panic!("args: {:?}", &args);
        let tasks: Vec<_> = (0..1)
            .map(|_| {
                let request_sender = request_sender.clone();
                tokio::spawn(
                    async move { request_sender.send_request(RequestType::Attributes).await },
                )
            })
            .collect();

        let results = join_all(tasks).await;

        let mut any_failed = false;
        for result in results {
            match result {
                Ok(Ok(json)) => {
                    println!("Request succeeded: {}", json);
                }
                Ok(Err(e)) => {
                    eprintln!("Request failed: {}", e);
                    any_failed = true;
                }
                Err(e) => {
                    eprintln!("Request failed: {}", e);
                    any_failed = true;
                }
            }
        }

        if any_failed {
            println!("Some requests failed");
        } else {
            println!("All requests succeeded");
        }
    }
}
