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
use crate::config::prompts::{print_error_message, print_info_message};

use super::tasks::{TaskProcessor, TaskType};

use processor::ComponentTaskData;

pub(crate) struct ComponentScraper {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
    /// Holds the additional metadata attacehed to the component results.
    ///
    /// Example:
    /// ```{
    ///   "data": {
    ///     "search": {
    ///       "applied_category": {
    ///         "ancestors": [
    ///           {
    ///             "id": "4161",
    ///             "name": "Electronic Parts",
    ///             "path": "/electronic-parts",
    ///           },
    ///           ...
    ///         ],
    ///         "id": "6334",
    ///         "name": "Mica Capacitors",
    ///         "path": "/electronic-parts/passive-components/capacitors/mica-capacitors",
    ///         "results": [ ... ] // <-- Component results are here.
    ///       }
    ///     }
    ///   }
    /// }
    /// ```
    component_response_metadata: Option<Value>,
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
            component_response_metadata: None,
        }
    }

    pub(crate) fn get_component_response_metadata(&self) -> Option<Value> {
        self.component_response_metadata.clone()
    }

    pub(crate) async fn process(
        &mut self,
        attribute_bucket_combinations: AttributeBucketCombinations,
    ) -> Result<Vec<Result<Vec<Value>>>> {
        print_info_message("Scraping component batches...", false);
        let component_counts = self
            .create_component_counts(attribute_bucket_combinations)
            .await;
        let component_counts_to_process = self
            .create_component_counts_to_process(component_counts)
            .await?;

        let results = self
            .process_tasks(TaskType::ComponentScraper, component_counts_to_process)
            .await;
        // Wait for the metadata.
        if let Some(receiver) = self.response_handler.clone().take_receiver().await {
            match receiver.await {
                Ok(metadata) => {
                    self.component_response_metadata = Some(metadata);
                }
                Err(_) => {
                    print_error_message(&"Failed to get component response metadata");
                }
            };
        };
        results
    }

    async fn create_component_counts_to_process(
        &self,
        component_counts: ComponentCounts,
    ) -> Result<VecDeque<ComponentTaskData>, anyhow::Error> {
        let component_counts_to_process = component_counts
            .component_counts
            .iter()
            .cloned()
            .map(|component_count| ComponentTaskData {
                component_count: component_count.clone(),
            })
            .collect::<VecDeque<_>>();
        Ok(component_counts_to_process)
    }

    async fn create_component_counts(
        &self,
        attribute_bucket_combinations: AttributeBucketCombinations,
    ) -> ComponentCounts {
        let mut component_counts = Vec::new();

        for combination in attribute_bucket_combinations.combinations {
            let mut start = 0;
            let limited_count = combination.component_count.min(1000);

            while start < limited_count {
                let end = (start + OCTOPART_COMPONENT_RESULT_LIMIT).min(limited_count);
                component_counts.push(ComponentCount {
                    attribute_bucket_combination: combination
                        .attribute_bucket_combination
                        .iter()
                        .map(
                            |(attribute_bucket_display_value, attribute_bucket)| AttributeBucket {
                                component_count: attribute_bucket.component_count,
                                display_value: attribute_bucket_display_value.to_string(),
                                float_value: attribute_bucket.float_value.clone(),
                            },
                        )
                        .collect(),
                    start,
                    end: OCTOPART_COMPONENT_RESULT_LIMIT,
                });

                start = end;
            }
        }

        ComponentCounts { component_counts }
    }
}
