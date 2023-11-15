use std::collections::HashMap;
use std::io::Error;
use std::time::Duration;

use log::debug;
use reqwest::{header, Client};
use serde_json::{json, Map, Value};

use crate::cli::Arguments;
use crate::config::categories::{ATTRIBUTES_MAP, CATEGORIES_MAP};
use crate::config::constants::ENDPOINT;
use crate::config::queries::{ATTRIBUTE_BUCKET_QUERY, PART_SEARCH_QUERY};

/// Enumerates different types of requests that can be handled.
pub(crate) enum RequestType {
    /// Request for attributes.
    Attributes,
    /// Request for parts, with filters and pagination options.
    Parts {
        filters: HashMap<String, Vec<String>>,
        start: usize,
        end: usize,
    },
    /// Request for counting components with optional attributes and filters.
    ComponentCount {
        attributes: Option<Vec<String>>,
        filters: Option<HashMap<String, Vec<String>>>,
    },
}

/// Manages the sending of different types of requests to a remote endpoint.
pub(crate) struct RequestSender {
    client: Client,
    pub(crate) category_name: Option<String>,
    category_id: Option<String>,
    attribute_ids: Option<Vec<String>>,
    pub(crate) attribute_names: Option<Vec<String>>,
}

impl RequestSender {
    /// Creates a new instance of `RequestSender` with initial configuration from the provided arguments.
    pub(crate) fn new(args: &Arguments) -> Self {
        let client = Client::builder()
            .redirect(reqwest::redirect::Policy::none())
            .connection_verbose(true)
            .http1_only()
            .http1_title_case_headers()
            .cookie_store(true)
            .timeout(Duration::from_secs(10))
            .build()
            .unwrap();
        let category_name = args.category_name.clone();
        let category_id = RequestSender::parse_category(args).ok();
        let attribute_names = args.attribute_names.clone();
        let attribute_ids = RequestSender::parse_attributes(args).ok();
        Self {
            client,
            category_name,
            category_id,
            attribute_names,
            attribute_ids,
        }
    }

    // Getter methods

    #[allow(dead_code)]
    pub(crate) fn get_category_name(&self) -> Option<&String> {
        self.category_name.as_ref()
    }

    #[allow(dead_code)]
    pub(crate) fn get_attribute_names(&self) -> Option<&Vec<String>> {
        self.attribute_names.as_ref()
    }

    #[allow(dead_code)]
    pub(crate) fn get_category_id(&self) -> Option<&String> {
        self.category_id.as_ref()
    }

    pub(crate) fn get_attribute_ids(&self) -> Option<&Vec<String>> {
        self.attribute_ids.as_ref()
    }

    /// Parses HTTP headers from the given arguments for constructing a request.
    ///
    /// # Arguments
    /// * `args` - Application arguments containing potential headers like cookies and user agent.
    ///
    /// # Returns
    /// A `Result` containing the `HeaderMap` on success, or an `Error` if header parsing fails.
    fn parse_headers(&self, args: &Arguments) -> Result<header::HeaderMap, Error> {
        let mut headers = header::HeaderMap::new();
        if let Some(px) = &args.px {
            headers.insert(
                reqwest::header::COOKIE,
                header::HeaderValue::from_str(&format!("_px={}", px.as_str()))
                    .expect("Failed to parse px header"),
            );
        }

        if let Some(user_agent) = &args.user_agent {
            headers.insert(
                reqwest::header::USER_AGENT,
                header::HeaderValue::from_str(user_agent.as_str())
                    .expect("Failed to parse user agent header"),
            );
        }
        Ok(headers)
    }

    /// Determines the category ID from the provided arguments.
    ///
    /// # Arguments
    /// * `args` - Application arguments containing the category name.
    ///
    /// # Returns
    /// A `Result` with the parsed category ID as `String` on success, or an `Error` if the category is not found.
    fn parse_category(args: &Arguments) -> Result<String, Error> {
        match &args.category_name {
            Some(category_name) => Ok((*CATEGORIES_MAP.get(category_name).unwrap()).to_string()),
            None => Err(Error::new(
                std::io::ErrorKind::InvalidInput,
                "Category name is required",
            )),
        }
    }

    /// Retrieves a list of attribute IDs based on the provided argument names.
    ///
    /// # Arguments
    /// * `args` - Application arguments containing attribute names.
    ///
    /// # Returns
    /// A `Result` with a `Vec<String>` of attribute IDs on success, or an `Error` if any attribute name is not found.
    fn parse_attributes(args: &Arguments) -> Result<Vec<String>, Error> {
        match &args.attribute_names {
            Some(attribute_names) => Ok(attribute_names
                .to_vec()
                .iter()
                .map(|attribute_name| (*ATTRIBUTES_MAP.get(attribute_name).unwrap()).to_string())
                .collect()),
            None => Err(Error::new(
                std::io::ErrorKind::InvalidInput,
                "Attribute names are required",
            )),
        }
    }

    /// Constructs the payload for the 'ComponentCount' request with optional attributes and filters.
    ///
    /// # Arguments
    /// * `attribute_names` - Optional list of attribute names to include in the request.
    /// * `filters` - Optional hashmap of filters to apply in the request.
    ///
    /// # Returns
    /// A `Value` representing the JSON payload for the request.
    pub(crate) fn get_component_count_payload(
        &self,
        attribute_names: Option<Vec<String>>,
        filters: Option<HashMap<String, Vec<String>>>,
    ) -> Value {
        // If attribute is Some, then we want to put it into a Vec, otherwise an empty Vec
        let filter_map = filters.unwrap_or_default();
        let mut filters = Map::new();
        filters.insert("category_id".to_string(), json!([self.category_id]));
        filter_map.iter().for_each(|(k, v)| {
            filters.insert(k.to_string(), json!(v));
        });
        let json_data = json!({
            "operationName": "FilterModalSearch",
            "variables": {
                "attribute_names": attribute_names,
                "currency": "USD",
                "filters": filters,
                "in_stock_only": false,
            },
            "query": ATTRIBUTE_BUCKET_QUERY.to_string(),
        });
        json_data
    }

    /// Builds the payload for an 'Attributes' request using configured attributes in the instance.
    ///
    /// # Returns
    /// A `Value` representing the JSON payload for the request.
    fn get_attributes_payload(&self) -> Value {
        let json_data = json!({
            "operationName": "FilterModalSearch",
            "variables": {
                "attribute_names": self.attribute_ids,
                "currency": "USD",
                "filters": {
                    "category_id": [self.category_id],
                },
                "in_stock_only": false,
            },
            "query": ATTRIBUTE_BUCKET_QUERY.to_string(),
        });
        json_data
    }

    /// Prepares the payload for a 'Parts' request with specified filters and pagination.
    ///
    /// # Arguments
    /// * `filters` - A hashmap of filters to apply in the request.
    /// * `start` - The starting index for pagination.
    /// * `end` - The ending index for pagination.
    ///
    /// # Returns
    /// A `Value` representing the JSON payload for the request.
    fn get_parts_payload(
        &self,
        filters: HashMap<String, Vec<String>>,
        start: usize,
        end: usize,
    ) -> Value {
        let filter_map = filters;
        let mut filters = Map::new();
        filters.insert("category_id".to_string(), json!([self.category_id]));
        filter_map.iter().for_each(|(k, v)| {
            filters.insert(k.to_string(), json!(v));
        });
        let json_data = json!({
            "operationName": "PricesViewSearch",
            "variables": {
                "country": "US",
                "currency": "USD",
                "filters": filters,
                "in_stock_only": false,
                "limit": end,
                "start": start,
            },
            "query": PART_SEARCH_QUERY.to_string(),
        });
        json_data
    }

    /// Sends a request to the server based on the specified `RequestType` and provided arguments.
    ///
    /// # Arguments
    /// * `args` - Application arguments to be used for the request.
    /// * `request_type` - The type of request to send (`Attributes`, `Parts`, `ComponentCount`).
    ///
    /// # Returns
    /// A `Result` containing the server response as a `Value` on success, or an `Error` if the request fails.
    pub(crate) async fn send_request(
        &self,
        args: &Arguments,
        request_type: RequestType,
    ) -> Result<Value, Error> {
        let headers = self.parse_headers(args)?;
        let body = match request_type {
            RequestType::Attributes => self.get_attributes_payload(),
            RequestType::Parts {
                filters,
                start,
                end,
            } => self.get_parts_payload(filters, start, end),
            RequestType::ComponentCount {
                attributes,
                filters,
            } => {
                let attributes = match attributes {
                    Some(attributes) => Some(attributes),
                    None => self.attribute_ids.clone(),
                };
                self.get_component_count_payload(attributes, filters)
            }
        };
        let response = self
            .client
            .post(ENDPOINT)
            .headers(headers)
            .json(&body)
            .send()
            .await
            .expect("Failed to send request");
        let response_string = response.text().await.map_err(|e| {
            Error::new(
                std::io::ErrorKind::Other,
                format!("Failed to parse response: {}", e),
            )
        })?;
        let response = serde_json::from_str(&response_string).map_err(|e| {
            debug!("Raw response string: {}", response_string);
            Error::new(
                std::io::ErrorKind::Other,
                format!("Failed to deserialize JSON: {}", e),
            )
        })?;
        Ok(response)
    }
}
