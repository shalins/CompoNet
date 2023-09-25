use scraper2::batch_manager::BatchManager;

#[tokio::main]
async fn main() -> Result<(), reqwest::Error> {
    let batch_manager = BatchManager::new(10);
    batch_manager.grab_component_count().await;
    Ok(())
}
