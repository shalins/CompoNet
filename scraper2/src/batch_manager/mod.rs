use log::debug;
use std::sync::Arc;
use tokio::sync::RwLock;

use anyhow::{anyhow, Result};

use crate::cli::Arguments;

mod fetch;
use fetch::components::ComponentScraper;
use fetch::counts::ComponentCounter;

mod request;
use crate::data_manager::DataManager;
use request::request_sender::{RequestSender, RequestType};
use request::response_handler::ResponseHandler;

mod types;

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

        let component_scraper = ComponentScraper::new(
            self.args.clone(),
            self.batch_size,
            request_sender.clone(),
            response_handler.clone(),
        );

        let data_manager = DataManager::new();

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

        debug!("Attribute Buckets: {:?}", attribute_buckets);

        let mut component_counter = ComponentCounter::new(
            self.args.clone(),
            self.batch_size,
            attribute_ids.clone(),
            attribute_buckets,
            request_sender.clone(),
            response_handler.clone(),
        )
        .expect("Failed to create component counter");

        let filter_combinations = component_counter.process().await?;

        println!("Finished grabbing bucket combination counts, grabbing components");

        let data = component_scraper.process(filter_combinations).await;
        data_manager.save_to_disk(data).await?;

        Ok(())
    }
}
