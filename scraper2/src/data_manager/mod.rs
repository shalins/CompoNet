use anyhow::Result;
use serde_json::Value;
use tokio::{fs::File, io::AsyncWriteExt};

pub struct DataManager {}

impl DataManager {
    pub fn new() -> Self {
        Self {}
    }

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

        let mut file = File::create("output.json").await?;
        file.write_all(serde_json::to_string_pretty(&file_content)?.as_bytes())
            .await?;

        Ok(())
    }
}
