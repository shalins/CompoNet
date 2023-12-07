pub const BATCH_SIZE: usize = 100;

pub(crate) const ENDPOINT: &str = "https://octopart.com/api/v4/internal";
pub(crate) const DEFAULT_USER_AGENT: &str = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.36";

/// The maximum number of components that can be requested in a single request.
pub(crate) const OCTOPART_COMPONENT_REQUEST_LIMIT: usize = 100;

/// The maximum number of components that can be scraped in a given category.
pub(crate) const OCTOPART_COMPONENT_COMBINATION_LIMIT: usize = 1000;

pub(crate) const DEFAULT_FILENAME: &str = "data";
pub(crate) const DEFAULT_SAVE_DIR: &str = "./data";

pub(crate) const METADATA_FILE_SUFFIX: &str = "metadata";
