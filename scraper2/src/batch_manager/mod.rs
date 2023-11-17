use std::sync::Arc;

use anyhow::{anyhow, Result};
use log::debug;
use tokio::sync::RwLock;

mod fetch;
mod request;
mod types;

use crate::batch_manager::fetch::attributes::AttributeScraper;
use crate::cli::Arguments;
use crate::data_manager::DataManager;

use fetch::components::ComponentScraper;
use fetch::counts::ComponentCounter;
use request::request_sender::RequestSender;
use request::response_handler::ResponseHandler;

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

        // 1. Get the attribute ids from the request sender.
        let attribute_shortnames = request_sender
            .get_attribute_shortnames()
            .ok_or_else(|| anyhow!("Failed to get attribute ids"))?;
        debug!("Attribute Shortnames: {:?}", attribute_shortnames);

        // 2. Get the attribute buckets from the attribute scraper.
        let attribute_scraper = AttributeScraper::new(
            self.args.clone(),
            request_sender.clone(),
            response_handler.clone(),
        );
        let attribute_buckets = attribute_scraper.process(attribute_shortnames).await?;
        debug!("Attribute Buckets: {:?}", attribute_buckets);

        // 3. Get the filter combination & component counts from the component counter.
        let mut component_counter = ComponentCounter::new(
            self.args.clone(),
            self.batch_size,
            attribute_shortnames.clone(),
            attribute_buckets,
            request_sender.clone(),
            response_handler.clone(),
        )
        .expect("Failed to create component counter");
        let component_counts = component_counter.process().await?;
        debug!("Component Counts: {:?}", component_counts);

        // 4. Get the components from the component scraper.
        let component_scraper = ComponentScraper::new(
            self.args.clone(),
            self.batch_size,
            request_sender.clone(),
            response_handler.clone(),
        );
        let components = component_scraper.process(component_counts).await;
        debug!("Components: {:?}", components);

        // 5. Save the components to disk.
        let data_manager = DataManager::new(self.args.clone());
        data_manager.save_to_disk(components).await?;
        debug!("Saved components to disk");

        Ok(())
    }
}
