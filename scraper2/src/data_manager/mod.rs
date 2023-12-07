use std::{
    path::{Path, PathBuf},
    sync::Arc,
};

use anyhow::{anyhow, Result};
use serde_json::{json, Value};
use tokio::{
    fs::{self, File},
    io::AsyncWriteExt,
    sync::RwLock,
};

use crate::{
    cli::{Arguments, Cli},
    config::{
        constants::{DEFAULT_FILENAME, DEFAULT_SAVE_DIR, METADATA_FILE_SUFFIX},
        prompts::{print_error_message, print_info_message},
    },
};

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
    pub(crate) async fn save_to_disk(
        &self,
        data: Result<Vec<Result<Vec<Value>>>>,
        octopart_metadata: &mut Option<Value>,
        scraper_metadata: Option<Value>,
    ) -> Result<()> {
        // 1. Flatten the structure by handling potential errors
        let cleaned_data: Vec<Value> = data?.into_iter().filter_map(Result::ok).flatten().collect();

        // 2. Serialize and write to a file
        let file_content = self.serialize(cleaned_data, octopart_metadata);

        // 3. Prepare filename and path
        let filename = self
            .args
            .read()
            .await
            .category_name
            .as_ref()
            .map(|name| Self::sanitize_filename(name))
            .unwrap_or_else(|| Self::sanitize_filename(DEFAULT_FILENAME));

        // 4. Write component data to disk
        let component_filepath = format!("{}/{}.json", DEFAULT_SAVE_DIR, filename);
        self.save_json_to_file(file_content, &component_filepath)
            .await?;

        // 5. Write metadata to disk
        if let Some(scraper_meta) = scraper_metadata {
            let scraper_filepath = format!(
                "{}/{}_{}.json",
                DEFAULT_SAVE_DIR, filename, METADATA_FILE_SUFFIX
            );
            self.save_json_to_file(scraper_meta, &scraper_filepath)
                .await?;
        }

        print_info_message("Done!", true);
        Ok(())
    }

    async fn save_json_to_file(&self, file_content: Value, filepath: &str) -> Result<()> {
        // Check and create data directory if not exists
        fs::create_dir_all(DEFAULT_SAVE_DIR).await?;

        // Check if file exists and prompt for overwrite
        if Path::new(&filepath).exists() {
            if Cli::prompt_user_for_file_overwrite() {
            } else {
                print_error_message(&"Aborted saving to disk.");
                return Ok(());
            }
        }

        // Write to disk
        println!();
        print_info_message(&format!("Writing {} to disk...", filepath), false);
        let mut file = File::create(filepath).await?;
        file.write_all(serde_json::to_string_pretty(&file_content)?.as_bytes())
            .await?;
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

    fn sanitize_filename(name: &str) -> String {
        name.to_lowercase()
            .chars()
            .map(|c| if c.is_alphanumeric() { c } else { '_' })
            .collect::<String>()
    }

    pub async fn combine_metadata_files(&self) -> Result<()> {
        let metadata_files = self.find_metadata_files().await?;
        let combined_metadata = self.combine_files_contents(&metadata_files).await?;

        self.save_json_to_file(
            combined_metadata,
            &format!("{}/scraper_{}.json", DEFAULT_SAVE_DIR, METADATA_FILE_SUFFIX),
        )
        .await?;

        for file_path in metadata_files {
            fs::remove_file(file_path).await?;
        }

        Ok(())
    }

    async fn find_metadata_files(&self) -> Result<Vec<PathBuf>> {
        let mut metadata_files = Vec::new();
        let mut dir = fs::read_dir(DEFAULT_SAVE_DIR).await?;

        while let Some(entry) = dir.next_entry().await? {
            let path = entry.path();
            if path.is_file()
                && path.extension().unwrap_or_default() == "json"
                && path
                    .file_stem()
                    .unwrap_or_default()
                    .to_string_lossy()
                    .ends_with(METADATA_FILE_SUFFIX)
            {
                metadata_files.push(path);
            }
        }

        Ok(metadata_files)
    }

    async fn combine_files_contents(&self, file_paths: &[PathBuf]) -> Result<Value> {
        let mut combined = serde_json::Map::new();

        for path in file_paths {
            let component_type = path
                .file_stem()
                .and_then(|stem| stem.to_str())
                .and_then(|stem_str| stem_str.split(&format!("_{}", METADATA_FILE_SUFFIX)).next())
                .ok_or_else(|| anyhow!("Failed to extract component type from file name"))?
                .to_string();

            let content = fs::read_to_string(path).await?;
            let json: Value = serde_json::from_str(&content)?;
            combined.insert(component_type, json);
        }

        Ok(Value::Object(combined))
    }
}
