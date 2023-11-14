use anyhow::Result;
use async_trait::async_trait;
use std::collections::{HashMap, VecDeque};
use std::vec;
use tokio::task::JoinHandle;

use super::ComponentCounter;

use crate::batch_manager::fetch::tasks::{process_tasks_helper, TaskProcessor};
use crate::batch_manager::request::request_sender::RequestType;
use crate::batch_manager::types::{Bucket, FilterCombinations};

#[derive(Debug, Clone)]
pub struct AttributeTaskData {
    pub last_attribute_bucket_key: String,
    pub attribute_keys: Vec<String>,
    pub attribute_values: Vec<Bucket>,
}

#[async_trait]
impl TaskProcessor for ComponentCounter {
    type TaskType = AttributeTaskData;
    type TaskResult = FilterCombinations;
    type TaskError = anyhow::Error;

    fn create_task(
        &self,
        task_data: Self::TaskType,
    ) -> JoinHandle<Result<Self::TaskResult, Self::TaskError>> {
        let mut filters = HashMap::new();
        for (key, bucket) in task_data
            .attribute_keys
            .iter()
            .zip(task_data.attribute_values.iter())
        {
            filters.insert(
                key.clone(),
                vec![bucket
                    .float_value
                    .clone()
                    .unwrap_or(bucket.display_value.clone())],
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
                        filters: Some(filters),
                    },
                )
                .await
                .map_err(anyhow::Error::new)?;

            let attribute_values = task_data
                .attribute_values
                .iter()
                .map(|bucket| {
                    bucket
                        .float_value
                        .clone()
                        .unwrap_or(bucket.display_value.clone())
                })
                .collect::<Vec<_>>();
            let current_attributes = task_data
                .attribute_keys
                .iter()
                .cloned()
                .zip(attribute_values)
                .collect::<HashMap<_, _>>();

            response_handler
                .extract_filter_combinations(
                    response,
                    current_attributes,
                    task_data.last_attribute_bucket_key,
                )
                .await
                .map_err(anyhow::Error::new)
        })
    }

    async fn process_tasks(
        &self,
        task_data_queue: VecDeque<Self::TaskType>,
    ) -> Result<Vec<Result<Self::TaskResult>>> {
        process_tasks_helper(self, task_data_queue, self.batch_size, self.args.clone()).await
    }
}
