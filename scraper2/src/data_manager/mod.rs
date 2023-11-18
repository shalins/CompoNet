use std::{path::Path, sync::Arc};

use anyhow::Result;
use serde_json::{json, Value};
use tokio::{
    fs::{self, File},
    io::AsyncWriteExt,
    sync::RwLock,
};

use crate::{
    cli::{Arguments, Cli},
    config::{
        constants::{DEFAULT_FILENAME, DEFAULT_SAVE_DIR},
        prompts::{print_error_message, print_info_message},
    },
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
    pub(crate) async fn save_to_disk(
        &self,
        data: Result<Vec<Result<Vec<Value>>>>,
        metadata: &mut Option<Value>,
    ) -> Result<()> {
        // 1. Flatten the structure by handling potential errors
        let cleaned_data: Vec<Value> = data?.into_iter().filter_map(Result::ok).flatten().collect();

        // 2. Serialize and write to a file
        let file_content = self.serialize(cleaned_data, metadata);

        // 3. Prepare filename and path
        let filename = &*self
            .args
            .clone()
            .read()
            .await
            .category_name
            .clone()
            .unwrap_or(DEFAULT_FILENAME.to_string());
        let filepath = format!("{}/{}.json", DEFAULT_SAVE_DIR, filename);

        // 4. Check and create data directory if not exists
        fs::create_dir_all(DEFAULT_SAVE_DIR).await?;

        // 5. Check if file exists and prompt for overwrite
        if Path::new(&filepath).exists() {
            if Cli::prompt_user_for_file_overwrite() {
            } else {
                print_error_message(&"Aborted saving to disk.");
                return Ok(());
            }
        }

        // 4. Write to disk
        println!();
        print_info_message(&format!("Writing {}.json to disk...", filename), false);
        let mut file = File::create(filepath).await?;
        file.write_all(serde_json::to_string_pretty(&file_content)?.as_bytes())
            .await?;

        print_info_message("Done!", true);
        Ok(())
    }

    fn serialize(&self, data: Vec<Value>, metadata: &mut Option<Value>) -> Value {
        if let Some(meta) = metadata.as_mut() {
            // Replace the contents of 'data/search/results' with 'data'
            if let Some(results) = meta.pointer_mut("/data/search/results") {
                *results = serde_json::to_value(data).unwrap_or_default();
            }
            json!(meta)
        } else {
            // Use the existing structure with 'data' directly
            json!({ "results": data })
        }
    }
}
