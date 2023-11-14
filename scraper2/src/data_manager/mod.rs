use std::sync::Arc;

use anyhow::Result;
use serde_json::Value;
use tokio::{fs::File, io::AsyncWriteExt, sync::RwLock};

use crate::{cli::Arguments, config::constants::DEFAULT_FILENAME};

#[derive(Default)]
pub struct DataManager {
    args: Arc<RwLock<Arguments>>,
}

impl DataManager {
    pub fn new(args: Arc<RwLock<Arguments>>) -> Self {
        Self { args }
    }
}

impl DataManager {
    pub async fn save_to_disk(&self, data: Result<Vec<Result<Vec<Value>>>>) -> Result<()> {
        // 1. Flatten the structure by handling potential errors
        let cleaned_data: Vec<Vec<Value>> = match data {
            Ok(inner_vec) => inner_vec.into_iter().filter_map(Result::ok).collect(),
            Err(_) => {
                eprintln!("Error in the outer result");
                vec![]
            }
        };

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

        let mut file = File::create(format!("{}.json", filename)).await?;
        file.write_all(serde_json::to_string_pretty(&file_content)?.as_bytes())
            .await?;

        Ok(())
    }
}
