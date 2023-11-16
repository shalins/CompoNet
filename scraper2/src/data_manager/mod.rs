use std::sync::Arc;

use anyhow::Result;
use serde_json::Value;
use tokio::{fs::File, io::AsyncWriteExt, sync::RwLock};

use crate::{
    cli::Arguments,
    config::{constants::DEFAULT_FILENAME, prompts::print_info_message},
};

#[derive(Default)]
pub(crate) struct DataManager {
    args: Arc<RwLock<Arguments>>,
}

impl DataManager {
    pub(crate) fn new(args: Arc<RwLock<Arguments>>) -> Self {
        Self { args }
    }
}

impl DataManager {
    pub(crate) async fn save_to_disk(&self, data: Result<Vec<Result<Vec<Value>>>>) -> Result<()> {
        // 1. Flatten the structure by handling potential errors
        let cleaned_data: Vec<Vec<Value>> = data?.into_iter().filter_map(Result::ok).collect();

        // 2. Serialize and write to a file
        let file_content = serde_json::json!({
            "data": cleaned_data
        });

        // 3. Get the filename from the arguments
        let filename = &*self
            .args
            .clone()
            .read()
            .await
            .category_name
            .clone()
            .unwrap_or(DEFAULT_FILENAME.to_string());

        // 4. Write to disk
        println!();
        print_info_message(&format!("Writing {}.json to disk...", filename), false);
        let mut file = File::create(format!("{}.json", filename)).await?;
        file.write_all(serde_json::to_string_pretty(&file_content)?.as_bytes())
            .await?;

        print_info_message("Done!", true);
        Ok(())
    }
}
