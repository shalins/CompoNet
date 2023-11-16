use anyhow::{anyhow, Result};

use crate::batch_manager::types::AttributeBuckets;

pub(crate) struct AttributeBucketMetadata {
    pub(crate) attribute_buckets: AttributeBuckets,
    pub(crate) last_attribute_bucket_display_value: String,
    pub(crate) second_last_attribute_bucket_display_value: Option<String>,
}

impl AttributeBucketMetadata {
    pub(crate) fn new(
        attribute_display_values: Vec<String>,
        attribute_buckets: AttributeBuckets,
    ) -> Result<Self> {
        let last_attribute_bucket_display_value = attribute_display_values
            .last()
            .cloned()
            .ok_or(anyhow!("Failed to get the last attribute key"))?;
        let mut second_last_attribute_bucket_display_value = None;
        if attribute_buckets.buckets.len() > 1 {
            second_last_attribute_bucket_display_value = attribute_display_values
                .get(attribute_display_values.len() - 2)
                .cloned();
        }

        Ok(Self {
            attribute_buckets,
            last_attribute_bucket_display_value,
            second_last_attribute_bucket_display_value,
        })
    }
}
