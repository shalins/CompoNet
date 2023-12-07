use std::sync::Arc;

use scraper2::batch_manager::BatchManager;
use scraper2::cli::Cli;
use scraper2::config::constants::BATCH_SIZE;
use scraper2::data_manager::DataManager;
use tokio::sync::RwLock;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    env_logger::init();

    let args = Cli::prompt();

    if args.combine_metadata {
        let data_manager = DataManager::new(Arc::new(RwLock::new(args)));
        data_manager.combine_metadata_files().await?;
    } else {
        let mut batch_manager = BatchManager::new(args, BATCH_SIZE);
        batch_manager.run().await?;
    }

    Ok(())
}
