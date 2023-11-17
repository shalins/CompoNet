use std::collections::{HashMap, VecDeque};

use anyhow::Result;
use async_trait::async_trait;
use serde_json::Value;
use tokio::task::JoinHandle;

use super::ComponentScraper;

use crate::batch_manager::{
    fetch::tasks::{process_tasks_helper, TaskProcessor, TaskType},
    request::request_sender::RequestType,
    types::ComponentCount,
};

#[derive(Clone, Debug)]
pub(crate) struct ComponentTaskData {
    pub(crate) component_count: ComponentCount,
}

#[async_trait]
impl TaskProcessor for ComponentScraper {
    type TaskData = ComponentTaskData;
    type TaskResult = Vec<Value>;
    type TaskError = anyhow::Error;

    fn create_task(
        &self,
        task_data: Self::TaskData,
    ) -> JoinHandle<Result<Self::TaskResult, Self::TaskError>> {
        let mut attribute_bucket_combinations = HashMap::new();
        for attribute_bucket in task_data
            .component_count
            .attribute_bucket_combination
            .iter()
        {
            attribute_bucket_combinations.insert(
                attribute_bucket.display_value.clone(),
                vec![attribute_bucket.float_value.clone().unwrap_or_default()],
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
                    RequestType::Components {
                        filters: attribute_bucket_combinations,
                        start: task_data.component_count.start,
                        end: task_data.component_count.end,
                    },
                )
                .await
                .map_err(anyhow::Error::new)?;

            response_handler.extract_components(response).await
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
