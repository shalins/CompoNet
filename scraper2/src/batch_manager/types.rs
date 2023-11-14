use std::collections::HashMap;

#[derive(Clone, Debug)]
pub struct Filter {
    pub display_id: String,
    pub bucket_value: String,
}

#[derive(Clone, Debug)]
pub struct PartitionedCombination {
    pub filters: Vec<Filter>,
    pub start: usize,
    pub end: usize,
}

#[derive(Clone, Debug)]
pub struct PartitionedCombinations {
    pub partitions: Vec<PartitionedCombination>,
}

#[derive(Clone, Debug)]
pub struct BucketPair {
    pub first: Option<(String, Bucket)>,
    pub second: (String, Bucket),
}

#[derive(Debug, Clone)]
pub struct Bucket {
    pub count: usize,
    pub display_value: String,
    pub float_value: Option<String>,
}

#[derive(Debug)]
pub struct AttributeBuckets {
    pub buckets: HashMap<String, Vec<Bucket>>,
}

#[derive(Debug, Default)]
pub struct FilterCombination {
    pub combination: HashMap<String, String>,
    pub count: usize,
}

#[derive(Debug, Default)]
pub struct FilterCombinations {
    pub combinations: Vec<FilterCombination>,
}
