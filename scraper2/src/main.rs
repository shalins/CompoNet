use log::info;
use scraper2::batch_manager::BatchManager;
use scraper2::cli::Cli;

#[tokio::main]
async fn main() -> Result<(), reqwest::Error> {
    info!("Starting batch manager");
    let args = Cli::prompt();
    let mut batch_manager = BatchManager::new(args, 100);
    batch_manager.run().await;
    Ok(())
}
