use std::collections::VecDeque;
use std::sync::Arc;
use std::time::Duration;

use anyhow::Result;
use chrono::Utc;
use serde_json::{json, Value};
use tokio::sync::RwLock;

pub(crate) mod processor;

use crate::batch_manager::request::request_sender::RequestSender;
use crate::batch_manager::request::response_handler::ResponseHandler;
use crate::batch_manager::types::{
    AttributeBucket, AttributeBucketCombinations, ComponentCount, ComponentCounts,
};

use crate::cli::Arguments;
use crate::config::constants::{
    OCTOPART_COMPONENT_COMBINATION_LIMIT, OCTOPART_COMPONENT_REQUEST_LIMIT,
};
use crate::config::prompts::{print_error_message, print_info_message};

use super::tasks::{TaskProcessor, TaskType};

use processor::ComponentTaskData;

pub(crate) struct ComponentScraper {
    args: Arc<RwLock<Arguments>>,
    batch_size: usize,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
    /// Holds the additional metadata from Octopart.
    ///
    /// Example:
    /// ```
    /// {
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
    octopart_component_metadata: Option<Value>,

    /// Holds the additional metadata from the Scraper tool.
    ///
    /// Example:
    /// ```
    /// {
    ///  "components_scraped": 23000,
    ///  "components_missed": 234,
    ///  "total_time": 0.02,
    ///  "date_collected": "2023-12-06T00:00:00Z",
    /// }
    /// ```
    scraper_component_metadata: Option<Value>,
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
            octopart_component_metadata: None,
            scraper_component_metadata: None,
        }
    }

    pub(crate) fn get_octopart_component_metadata(&self) -> Option<Value> {
        self.octopart_component_metadata.clone()
    }

    pub(crate) fn get_scraper_component_metadata(&mut self, total_time: Duration) -> Option<Value> {
        if self.scraper_component_metadata.is_none() {
            self.scraper_component_metadata = Some(json!({
                "components_scraped": 0,
                "components_missed": 0,
                "total_time": total_time.as_secs_f64(),
                "date_collected": Utc::now().timestamp(),
            }));
        } else {
            self.scraper_component_metadata.as_mut().map(|metadata| {
                metadata["total_time"] = json!(total_time.as_secs_f64());
                metadata
            });
        }
        self.scraper_component_metadata.clone()
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
        // Wait for the Octopart metadata.
        if let Some(receiver) = self.response_handler.clone().take_receiver().await {
            match receiver.await {
                Ok(metadata) => {
                    self.octopart_component_metadata = Some(metadata);
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
        &mut self,
        attribute_bucket_combinations: AttributeBucketCombinations,
    ) -> ComponentCounts {
        let mut component_counts = Vec::new();
        let mut total_components_scraped = 0;
        let mut total_components_missed = 0;

        for combination in attribute_bucket_combinations.combinations {
            let mut start = 0;
            let limited_count = combination
                .component_count
                .min(OCTOPART_COMPONENT_COMBINATION_LIMIT);

            total_components_scraped += limited_count;
            if combination.component_count > OCTOPART_COMPONENT_COMBINATION_LIMIT {
                total_components_missed +=
                    combination.component_count - OCTOPART_COMPONENT_COMBINATION_LIMIT;
            }

            while start < limited_count {
                let end = (start + OCTOPART_COMPONENT_REQUEST_LIMIT).min(limited_count);
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
                    end: OCTOPART_COMPONENT_REQUEST_LIMIT,
                });

                start = end;
            }
        }

        self.fill_scraper_metadata(total_components_scraped, total_components_missed);

        ComponentCounts { component_counts }
    }

    fn fill_scraper_metadata(&mut self, components_scraped: usize, components_missed: usize) {
        self.scraper_component_metadata = Some(json!({
            "components_scraped": components_scraped,
            "components_missed": components_missed,
            "date_collected": Utc::now().timestamp(),
        }));
    }
}
