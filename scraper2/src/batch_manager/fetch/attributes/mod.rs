use std::sync::Arc;

use anyhow::Result;
use tokio::sync::RwLock;

use crate::{
    batch_manager::{
        request::{
            request_sender::{RequestSender, RequestType},
            response_handler::ResponseHandler,
        },
        types::AttributeBuckets,
    },
    cli::Arguments,
};

pub struct AttributeScraper {
    args: Arc<RwLock<Arguments>>,
    request_sender: Arc<RequestSender>,
    response_handler: Arc<ResponseHandler>,
}

impl AttributeScraper {
    pub fn new(
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

    pub async fn process(&self, attribute_ids: &[String]) -> Result<AttributeBuckets> {
        loop {
            let attribute_response = self
                .request_sender
                .clone()
                .send_request(&*self.args.read().await, RequestType::Attributes)
                .await
                .map_err(anyhow::Error::new)?;

            match self
                .response_handler
                .clone()
                .extract_buckets(attribute_response, attribute_ids)
                .await
                .map_err(anyhow::Error::new)
            {
                Ok(buckets) => return Ok(buckets),
                Err(e) => {
                    eprintln!("Failed to extract buckets: {:?}", e);
                    self.args.clone().write().await.prompt_user_for_new_px_key();
                    continue;
                }
            }
        }
    }
}
