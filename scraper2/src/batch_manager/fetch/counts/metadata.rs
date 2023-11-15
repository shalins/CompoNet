use anyhow::{anyhow, Result};

use crate::batch_manager::types::AttributeBuckets;

pub(crate) struct AttributeBucketMetadata {
    pub(crate) attribute_buckets: AttributeBuckets,
    pub(crate) last_attribute_bucket_key: String,
    pub(crate) second_last_attribute_bucket_key: Option<String>,
}

impl AttributeBucketMetadata {
    pub(crate) fn new(
        attribute_ids: Vec<String>,
        attribute_buckets: AttributeBuckets,
    ) -> Result<Self> {
        let last_attribute_bucket_key = attribute_ids
            .last()
            .cloned()
            .ok_or(anyhow!("Failed to get the last attribute key"))?;
        let mut second_last_attribute_bucket_key = None;
        if attribute_buckets.buckets.len() > 1 {
            second_last_attribute_bucket_key = attribute_ids.get(attribute_ids.len() - 2).cloned();
        }

        Ok(Self {
            attribute_buckets,
            last_attribute_bucket_key,
            second_last_attribute_bucket_key,
        })
    }
}
