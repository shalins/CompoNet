use serde_json::Value;
use std::collections::{HashMap, VecDeque};
use std::sync::Arc;
use std::vec;
use tokio::sync::RwLock;
use tokio::task::JoinHandle;

use anyhow::{anyhow, Result};

use crate::cli::Arguments;

use crate::batch_manager::request::request_sender::{RequestSender, RequestType};
use crate::batch_manager::request::response_handler::{
    Filter, FilterCombinations,
    PartitionedCombination, PartitionedCombinations, ResponseHandler,
};
use crate::config::constants::OCTOPART_DEFAULT_RESULT_LIMIT;

pub struct ComponentScraper {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
}

impl ComponentScraper {
    pub fn new(args: Arc<RwLock<Arguments>>, batch_size: usize) -> Self {
        Self { args, batch_size }
    }

    pub async fn get_partitioned_combinations(
        &self,
        filter_combinations: FilterCombinations,
    ) -> PartitionedCombinations {
        let mut partitions = Vec::new();
        for combination in filter_combinations.combinations {
            let mut start = 0;
            let limited_count = combination.count.min(1000);

            while start < limited_count {
                let end = (start + OCTOPART_DEFAULT_RESULT_LIMIT).min(limited_count);
                partitions.push(PartitionedCombination {
                    filters: combination
                        .combination
                        .iter()
                        .map(|(key, value)| Filter {
                            display_id: key.to_string(),
                            bucket_value: value.to_string(),
                        })
                        .collect(),
                    start,
                    end: OCTOPART_DEFAULT_RESULT_LIMIT,
                });

                start = end;
            }
        }

        PartitionedCombinations { partitions }
    }

    pub async fn process_components(
        &self,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
        partitioned_combinations: PartitionedCombinations,
    ) -> Result<Vec<Result<Vec<Value>>>> {
        let mut partitions_to_process = self.get_partitions(partitioned_combinations).await?;
        self.process_tasks_combinations(
            request_sender,
            response_handler,
            &mut partitions_to_process,
        )
        .await
    }

    async fn get_partitions(
        &self,
        partitioned_combinations: PartitionedCombinations,
    ) -> Result<VecDeque<PartitionedCombination>, anyhow::Error> {
        let buckets_to_process = partitioned_combinations
            .partitions
            .iter()
            .cloned()
            .collect::<VecDeque<_>>();
        Ok(buckets_to_process)
    }

    async fn process_tasks_combinations(
        &self,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
        partitions_to_process: &mut VecDeque<PartitionedCombination>,
    ) -> Result<Vec<Result<Vec<Value>>>> {
        let mut results = Vec::new();
        let mut tasks = Vec::new();

        while !partitions_to_process.is_empty() {
            if let Some(partition) = partitions_to_process.pop_front() {
                let task = self.create_task_components(
                    request_sender.clone(),
                    response_handler.clone(),
                    partition.clone(),
                );
                tasks.push((task, partition));
            }

            if tasks.len() >= self.batch_size || partitions_to_process.is_empty() {
                println!("Tasks left: {}", partitions_to_process.len());
                let associated_partitions: Vec<_> = tasks
                    .iter()
                    .map(|(_, partition)| partition.clone())
                    .collect();
                let batch_results = self
                    .join_current_partition_tasks(std::mem::take(&mut tasks))
                    .await;
                let batch_results_with_partitions: Vec<_> = batch_results
                    .into_iter()
                    .zip(associated_partitions)
                    .collect();

                let failed_partitions: Vec<_> = batch_results_with_partitions
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

                if !failed_partitions.is_empty() {
                    self.args.write().await.prompt_user_for_new_px_key();
                    partitions_to_process.extend(failed_partitions);
                } else {
                    results.extend(
                        batch_results_with_partitions
                            .into_iter()
                            .map(|(result, _)| result),
                    );
                }
            }
        }
        Ok(results)
    }

    fn create_task_components(
        &self,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
        partition: PartitionedCombination,
    ) -> JoinHandle<Result<Vec<Value>, anyhow::Error>> {
        let mut filters = HashMap::new();
        for filter in partition.filters.iter() {
            filters.insert(filter.display_id.clone(), vec![filter.bucket_value.clone()]);
        }

        let args = self.args.clone();
        let request_sender = request_sender.clone();
        let response_handler = response_handler.clone();

        tokio::spawn(async move {
            let response = request_sender
                .clone()
                .send_request(
                    &*args.read().await,
                    RequestType::Parts {
                        filters,
                        start: partition.start,
                        end: partition.end,
                    },
                )
                .await
                .map_err(anyhow::Error::new)?;

            response_handler.extract_components(response).await
        })
    }

    async fn join_current_partition_tasks(
        &self,
        current_tasks: Vec<(
            JoinHandle<Result<Vec<Value>, anyhow::Error>>,
            PartitionedCombination,
        )>,
    ) -> Vec<Result<Vec<Value>>> {
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

}