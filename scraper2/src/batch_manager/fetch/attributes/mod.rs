use std::sync::Arc;

use anyhow::Result;
use tokio::sync::RwLock;

use crate::{
    batch_manager::{
        fetch::tasks::TaskType,
        request::{
            request_sender::{RequestSender, RequestType},
            response_handler::ResponseHandler,
        },
        types::AttributeBuckets,
    },
    cli::Arguments,
    config::prompts::print_error_message,
};

pub(crate) struct AttributeScraper {
    args: Arc<RwLock<Arguments>>,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
}

impl AttributeScraper {
    pub(crate) fn new(
        args: Arc<RwLock<Arguments>>,
        request_sender: Arc<RequestSender>,
        response_handler: Arc<ResponseHandler>,
    ) -> Self {
        Self {
            args,
            request_sender,
            response_handler,
        }
    }

    pub(crate) async fn process(
        &self,
        attribute_bucket_display_values: &[String],
    ) -> Result<AttributeBuckets> {
        loop {
            let args_clone = self.args.read().await;
            let attribute_bucket_response = match self
                .request_sender
                .clone()
                .send_request(&args_clone, RequestType::Attributes)
                .await
                .map_err(anyhow::Error::new)
            {
                Ok(json_response) => json_response,
                Err(_) => {
                    print_error_message(&TaskType::AttributeScraper, 1);

                    // Explicitly drop the read lock before acquiring a write lock, otherwise a
                    // deadlock will occur.
                    drop(args_clone);

                    self.args.write().await.prompt_user_for_new_px_key();
                    continue;
                }
            };

            return self
                .response_handler
                .clone()
                .extract_attribute_buckets(
                    attribute_bucket_response,
                    attribute_bucket_display_values,
                )
                .await
                .map_err(anyhow::Error::new);
        }
    }
}
