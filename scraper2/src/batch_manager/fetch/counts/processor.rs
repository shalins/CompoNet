use std::collections::{HashMap, VecDeque};
use std::vec;

use anyhow::Result;
use async_trait::async_trait;
use tokio::task::JoinHandle;

use crate::batch_manager::fetch::tasks::{process_tasks_helper, TaskProcessor, TaskType};
use crate::batch_manager::request::request_sender::RequestType;
use crate::batch_manager::types::{AttributeBucket, AttributeBucketCombinations};

use super::ComponentCounter;

#[derive(Debug, Clone)]
pub(crate) struct AttributeTaskData {
    pub(crate) last_attribute_bucket_key: String,
    pub(crate) attribute_bucket_display_values: Vec<String>,
    pub(crate) attribute_buckets: Vec<AttributeBucket>,
}

#[async_trait]
impl TaskProcessor for ComponentCounter {
    type TaskData = AttributeTaskData;
    type TaskResult = AttributeBucketCombinations;
    type TaskError = anyhow::Error;

    fn create_task(
        &self,
        task_data: Self::TaskData,
    ) -> JoinHandle<Result<Self::TaskResult, Self::TaskError>> {
        let mut attribute_bucket_combinations = HashMap::new();
        for (attribute_display_value, attribute_bucket) in task_data
            .attribute_bucket_display_values
            .iter()
            .zip(task_data.attribute_buckets.iter())
        {
            attribute_bucket_combinations.insert(
                attribute_display_value.clone(),
                vec![attribute_bucket
                    .float_value
                    .clone()
                    .unwrap_or(attribute_bucket.display_value.clone())],
            );
        }

        let args = self.args.clone();
        let request_sender = self.request_sender.clone();
        let response_handler = self.response_handler.clone();

        tokio::spawn(async move {
            let response = request_sender
                .clone()
                .send_request(
                    &*args.read().await,
                    RequestType::ComponentCount {
                        attributes: Some(vec![task_data.last_attribute_bucket_key.clone()]),
                        filters: Some(attribute_bucket_combinations),
                    },
                )
                .await
                .map_err(anyhow::Error::new)?;

            let attribute_buckets = task_data.attribute_buckets;
            let current_attribute_bucket_combinations = task_data
                .attribute_bucket_display_values
                .iter()
                .cloned()
                .zip(attribute_buckets)
                .collect::<HashMap<_, _>>();

            response_handler
                .extract_attribute_bucket_combinations(
                    response,
                    current_attribute_bucket_combinations,
                    task_data.last_attribute_bucket_key,
                )
                .await
                .map_err(anyhow::Error::new)
        })
    }

    async fn process_tasks(
        &self,
        task_type: TaskType,
        task_data_queue: VecDeque<Self::TaskData>,
    ) -> Result<Vec<Result<Self::TaskResult>>> {
        process_tasks_helper(
            self,
            task_type,
            task_data_queue,
            self.batch_size,
            self.args.clone(),
        )
        .await
    }
}
