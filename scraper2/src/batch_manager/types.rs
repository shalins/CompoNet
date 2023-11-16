use std::collections::HashMap;

#[derive(Clone, Debug)]
pub(crate) struct ComponentCount {
    pub(crate) attribute_bucket_combination: Vec<AttributeBucket>,
    pub(crate) start: usize,
    pub(crate) end: usize,
}

#[derive(Clone, Debug)]
pub(crate) struct ComponentCounts {
    pub(crate) component_counts: Vec<ComponentCount>,
}

#[derive(Debug, Default)]
pub(crate) struct AttributeBucketCombination {
    pub(crate) attribute_bucket_combination: HashMap<String, AttributeBucket>,
    pub(crate) component_count: usize,
}

#[derive(Debug, Default)]
pub(crate) struct AttributeBucketCombinations {
    pub(crate) combinations: Vec<AttributeBucketCombination>,
}

// Pair of attribute buckets ->
// e.g. if the attributes are voltage rating dc and capacitance, a bucket pair would be
// (first: 10v, second: 1uf) for example where the id is the display name and the bucket is the
// bucket value
#[derive(Clone, Debug)]
pub(crate) struct AttributeBucketPair {
    pub(crate) third_last_attribute_bucket: Option<(String, AttributeBucket)>,
    pub(crate) second_last_attribute_bucket: (String, AttributeBucket),
}

#[derive(Debug, Clone)]
pub(crate) struct AttributeBucket {
    pub(crate) component_count: usize,
    pub(crate) display_value: String,
    pub(crate) float_value: Option<String>,
}

#[derive(Debug)]
pub(crate) struct AttributeBuckets {
    pub(crate) buckets: HashMap<String, Vec<AttributeBucket>>,
}
