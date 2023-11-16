use std::collections::VecDeque;
use std::sync::Arc;

use anyhow::Result;
use serde_json::Value;
use tokio::sync::RwLock;

pub(crate) mod processor;

use crate::batch_manager::request::request_sender::RequestSender;
use crate::batch_manager::request::response_handler::ResponseHandler;
use crate::batch_manager::types::{
    AttributeBucket, AttributeBucketCombinations, ComponentCount, ComponentCounts,
};

use crate::cli::Arguments;
use crate::config::constants::OCTOPART_COMPONENT_RESULT_LIMIT;
use crate::config::prompts::print_info_message;

use super::tasks::{TaskProcessor, TaskType};

use processor::ComponentTaskData;

pub(crate) struct ComponentScraper {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
}

impl ComponentScraper {
    pub(crate) fn new(
        args: Arc<RwLock<Arguments>>,
        batch_size: usize,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Self {
        Self {
            args,
            batch_size,
            request_sender,
            response_handler,
        }
    }

    pub(crate) async fn process(
        &self,
        filter_combinations: AttributeBucketCombinations,
    ) -> Result<Vec<Result<Vec<Value>>>> {
        print_info_message("Scraping component batches...", false);
        let partitions = self.get_partitioned_combinations(filter_combinations).await;
        let partitions_to_process = self.get_partitions(partitions).await?;
        self.process_tasks(TaskType::ComponentScrape, partitions_to_process)
            .await
    }

    async fn get_partitions(
        &self,
        partitioned_combinations: ComponentCounts,
    ) -> Result<VecDeque<ComponentTaskData>, anyhow::Error> {
        let buckets_to_process = partitioned_combinations
            .component_counts
            .iter()
            .cloned()
            .map(|partition| ComponentTaskData {
                component_count: partition.clone(),
            })
            .collect::<VecDeque<_>>();
        Ok(buckets_to_process)
    }

    async fn get_partitioned_combinations(
        &self,
        filter_combinations: AttributeBucketCombinations,
    ) -> ComponentCounts {
        let mut partitions = Vec::new();

        for combination in filter_combinations.combinations {
            let mut start = 0;
            let limited_count = combination.component_count.min(1000);

            while start < limited_count {
                let end = (start + OCTOPART_COMPONENT_RESULT_LIMIT).min(limited_count);
                partitions.push(ComponentCount {
                    attribute_bucket_combination: combination
                        .attribute_bucket_combination
                        .iter()
                        .map(|(key, value)| AttributeBucket {
                            component_count: value.component_count,
                            display_value: key.to_string(),
                            float_value: value.float_value.clone(),
                        })
                        .collect(),
                    start,
                    end: OCTOPART_COMPONENT_RESULT_LIMIT,
                });

                start = end;
            }
        }

        ComponentCounts {
            component_counts: partitions,
        }
    }
}
