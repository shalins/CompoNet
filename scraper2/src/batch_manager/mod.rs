use std::collections::{HashMap, VecDeque};
use std::sync::Arc;
use std::vec;
use tokio::sync::RwLock;
use tokio::task::JoinHandle;

use anyhow::{anyhow, Result};

use crate::cli::Arguments;
use crate::request_sender::{RequestSender, RequestType};
use crate::response_handler::{
    AttributeBuckets, Bucket, BucketPair, FilterCombination, FilterCombinations, ResponseHandler,
};

pub struct BatchManager {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
}

impl BatchManager {
    pub fn new(args: Arguments, batch_size: usize) -> Self {
        let args = Arc::new(RwLock::new(args));
        Self { batch_size, args }
    }

    pub async fn run(&mut self) -> Result<()> {
        let request_sender = Arc::new(RequestSender::new(&*self.args.read().await));
        let response_handler = Arc::new(ResponseHandler::new());

        // 1. Get the attribute ids from the request sender.
        let attribute_ids = request_sender
            .get_attribute_ids()
            .ok_or_else(|| anyhow!("Failed to get attribute ids"))?;

        // 2. Send a request to get the buckets for all the attributes.
        let attribute_response = request_sender
            .clone()
            .send_request(&*self.args.read().await, RequestType::Attributes)
            .await
            .map_err(anyhow::Error::new)?;

        // 3. Join the attribute ids with the buckets from the response.
        let attribute_buckets = response_handler
            .clone()
            .extract_buckets(attribute_response, attribute_ids)
            .await
            .map_err(anyhow::Error::new)?;

        println!("Attribute Buckets: {:?}", attribute_buckets);

        self.grab_bucket_combination_counts(
            request_sender.clone(),
            response_handler.clone(),
            attribute_ids,
            attribute_buckets,
        )
        .await?;
        Ok(())
    }

    async fn grab_bucket_combination_counts(
        &mut self,
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
                self.process_buckets(
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
                self.process_buckets(
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

    async fn join_current_tasks(
        &self,
        current_tasks: Vec<(
            JoinHandle<Result<FilterCombinations, anyhow::Error>>,
            BucketPair,
        )>,
    ) -> Vec<Result<FilterCombinations>> {
        let futures: Vec<_> = current_tasks
            .into_iter()
            .map(|(handle, _)| handle)
            .collect();
        let task_results = futures::future::join_all(futures).await;

        task_results
            .into_iter()
            .map(|task_result| match task_result {
                Ok(ok_value) => ok_value,
                Err(join_error) => Err(anyhow!(join_error)),
            })
            .collect()
    }

    async fn get_bucket_pairs(
        &self,
        buckets: HashMap<String, Vec<Bucket>>,
        second_last_key: String,
        last_key: String,
    ) -> Result<VecDeque<BucketPair>, anyhow::Error> {
        let mut buckets_to_process = VecDeque::new();
        let filtered_buckets: HashMap<String, Vec<Bucket>> = buckets
            .iter()
            .filter(|(key, _)| *key != &second_last_key && *key != &last_key)
            .map(|(key, value)| (key.clone(), value.clone())) // clone the keys and values
            .collect();
        if filtered_buckets.is_empty() {
            let second_last_attribute_bucket_values = buckets
                .get(&second_last_key)
                .ok_or(anyhow!("Failed to get first attribute bucket"))?
                .clone();
            let combinations: Vec<_> = second_last_attribute_bucket_values
                .iter()
                .map(|bucket| BucketPair {
                    first: None,
                    second: { (second_last_key.clone(), bucket.clone()) },
                })
                .collect();
            buckets_to_process.extend(combinations);
        } else {
            for (third_to_last_attribute_bucket_key, third_to_last_attribute_bucket_values) in
                filtered_buckets
            {
                for third_to_last_attribute_bucket_value in third_to_last_attribute_bucket_values {
                    let second_last_attribute_bucket_values = buckets
                        .get(&second_last_key)
                        .ok_or(anyhow!("Failed to get first attribute bucket"))?
                        .clone();
                    let combinations: Vec<_> = second_last_attribute_bucket_values
                        .iter()
                        .map(|bucket| BucketPair {
                            first: Some((
                                third_to_last_attribute_bucket_key.clone(),
                                third_to_last_attribute_bucket_value.clone(),
                            )),
                            second: { (second_last_key.clone(), bucket.clone()) },
                        })
                        .collect();
                    buckets_to_process.extend(combinations);
                }
            }
        }

        Ok(buckets_to_process)
    }

    fn create_task(
        &self,
        last_attribute_bucket_key: String,
        attribute_keys: Vec<String>,
        attribute_values: Vec<Bucket>,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> JoinHandle<Result<FilterCombinations, anyhow::Error>> {
        let mut filters = HashMap::new();
        for (key, bucket) in attribute_keys.iter().zip(attribute_values.iter()) {
            filters.insert(
                key.clone(),
                vec![bucket
                    .float_value
                    .clone()
                    .unwrap_or(bucket.display_value.clone())],
            );
        }

        let args = self.args.clone();
        let request_sender = request_sender.clone();
        let response_handler = response_handler.clone();

        tokio::spawn(async move {
            let response = request_sender
                .clone()
                .send_request(
                    &*args.read().await,
                    RequestType::ComponentCount {
                        attributes: Some(vec![last_attribute_bucket_key]),
                        filters: Some(filters),
                    },
                )
                .await
                .map_err(anyhow::Error::new)?;

            let current_attributes = attribute_values
                .iter()
                .map(|bucket| bucket.display_value.clone())
                .collect::<Vec<_>>();

            response_handler
                .extract_filter_combinations(response, current_attributes)
                .await
                .map_err(anyhow::Error::new)
        })
    }

    async fn process_tasks(
        &self,
        buckets_to_process: &mut VecDeque<BucketPair>,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
        last_key: &str,
    ) -> Result<Vec<Result<FilterCombinations>>> {
        let mut results = Vec::new();
        let mut tasks = Vec::new();

        while !buckets_to_process.is_empty() {
            if let Some(bucket) = buckets_to_process.pop_front() {
                let (attribute_keys, attribute_values) = match &bucket.first {
                    Some((k, v)) => (
                        vec![k.clone(), bucket.second.0.clone()],
                        vec![v.clone(), bucket.second.1.clone()],
                    ),
                    None => (vec![bucket.second.0.clone()], vec![bucket.second.1.clone()]),
                };

                let task = self.create_task(
                    last_key.to_string(),
                    attribute_keys,
                    attribute_values,
                    request_sender.clone(),
                    response_handler.clone(),
                );
                tasks.push((task, bucket));
            }

            if tasks.len() >= self.batch_size || buckets_to_process.is_empty() {
                let associated_buckets: Vec<_> =
                    tasks.iter().map(|(_, bucket)| bucket.clone()).collect();
                let batch_results = self.join_current_tasks(std::mem::take(&mut tasks)).await;
                let batch_results_with_buckets: Vec<_> =
                    batch_results.into_iter().zip(associated_buckets).collect();

                let failed_buckets: Vec<_> = batch_results_with_buckets
                    .iter()
                    .filter_map(|(res, bucket)| {
                        if res.is_err() {
                            println!("Error: {:?}", res.as_ref().err().unwrap());
                            Some(bucket.clone())
                        } else {
                            None
                        }
                    })
                    .collect();

                if !failed_buckets.is_empty() {
                    self.args.write().await.prompt_user_for_new_px_key();
                    buckets_to_process.extend(failed_buckets);
                } else {
                    results.extend(
                        batch_results_with_buckets
                            .into_iter()
                            .map(|(result, _)| result),
                    );
                }
            }
        }
        println!("Results: {:?}", results);

        Ok(results)
    }

    async fn process_buckets(
        &self,
        second_last_key: String,
        last_key: String,
        buckets: HashMap<String, Vec<Bucket>>,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Result<Vec<Result<FilterCombinations>>> {
        let mut buckets_to_process = self
            .get_bucket_pairs(buckets, second_last_key, last_key.clone())
            .await?;
        self.process_tasks(
            &mut buckets_to_process,
            request_sender,
            response_handler,
            &last_key,
        )
        .await
    }
}
