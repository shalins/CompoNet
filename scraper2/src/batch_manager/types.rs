use std::collections::HashMap;

#[derive(Clone, Debug)]
pub(crate) struct Filter {
    pub(crate) display_id: String,
    pub(crate) bucket_value: String,
}

#[derive(Clone, Debug)]
pub(crate) struct PartitionedCombination {
    pub(crate) filters: Vec<Filter>,
    pub(crate) start: usize,
    pub(crate) end: usize,
}

#[derive(Clone, Debug)]
pub(crate) struct PartitionedCombinations {
    pub(crate) partitions: Vec<PartitionedCombination>,
}

#[derive(Clone, Debug)]
pub(crate) struct BucketPair {
    pub(crate) first: Option<(String, Bucket)>,
    pub(crate) second: (String, Bucket),
}

#[derive(Debug, Clone)]
pub(crate) struct Bucket {
    pub(crate) count: usize,
    pub(crate) display_value: String,
    pub(crate) float_value: Option<String>,
}

#[derive(Debug)]
pub(crate) struct AttributeBuckets {
    pub(crate) buckets: HashMap<String, Vec<Bucket>>,
}

#[derive(Debug, Default)]
pub(crate) struct FilterCombination {
    pub(crate) combination: HashMap<String, String>,
    pub(crate) count: usize,
}

#[derive(Debug, Default)]
pub(crate) struct FilterCombinations {
    pub(crate) combinations: Vec<FilterCombination>,
}
