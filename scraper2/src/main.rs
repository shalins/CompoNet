use scraper2::batch_manager::BatchManager;
use scraper2::cli::Cli;
use scraper2::config::constants::BATCH_SIZE;

#[tokio::main]
async fn main() -> Result<(), anyhow::Error> {
    env_logger::init();

    let args = Cli::prompt();
    let mut batch_manager = BatchManager::new(args, BATCH_SIZE);
    batch_manager.run().await
}
