use std::collections::HashMap;
use std::io::Error;

use reqwest::{header::HeaderMap, header::HeaderValue, Client};
use serde_json::{json, Map, Value};

use crate::categories::{ATTRIBUTES_CACHE, CATEGORIES_CACHE};
use crate::cli::Arguments;
use crate::config::{ATTRIBUTE_BUCKET_QUERY, ENDPOINT, PART_SEARCH_QUERY};

pub enum RequestType {
    Attributes,
    Parts,
    ComponentCount {
        attributes: Option<Vec<String>>,
        filters: Option<HashMap<String, Vec<String>>>,
    },
}

pub struct RequestSender {
    client: Client,
    headers: Option<HeaderMap>,
    pub category_name: Option<String>,
    category_id: Option<String>,
    attribute_ids: Option<Vec<String>>,
    pub attribute_names: Option<Vec<String>>,
}

impl RequestSender {
    pub fn new(args: &Arguments) -> Self {
        let client = Client::new();
        let headers = RequestSender::parse_headers(args).ok();
        let category_name = args.category_name.clone();
        let category_id = RequestSender::parse_category(args).ok();
        let attribute_names = args.attribute_names.clone();
        let attribute_ids = RequestSender::parse_attributes(args).ok();
        Self {
            client,
            headers,
            category_name,
            category_id,
            attribute_names,
            attribute_ids,
        }
    }

    pub fn get_category_name(&self) -> Option<&String> {
        self.category_name.as_ref()
    }

    pub fn get_attribute_names(&self) -> Option<&Vec<String>> {
        self.attribute_names.as_ref()
    }

    pub fn get_category_id(&self) -> Option<&String> {
        self.category_id.as_ref()
    }

    pub fn get_attribute_ids(&self) -> Option<&Vec<String>> {
        self.attribute_ids.as_ref()
    }

    fn parse_headers(args: &Arguments) -> Result<HeaderMap, Error> {
        let mut headers = HeaderMap::new();
        if let Some(px) = &args.px {
            headers.insert(
                reqwest::header::COOKIE,
                HeaderValue::from_str(px.as_str()).expect("Failed to parse px header"),
            );
        }
        if let Some(user_agent) = &args.user_agent {
            headers.insert(
                reqwest::header::USER_AGENT,
                HeaderValue::from_str(user_agent.as_str())
                    .expect("Failed to parse user agent header"),
            );
        }
        Ok(headers)
    }

    fn parse_category(args: &Arguments) -> Result<String, Error> {
        match &args.category_name {
            Some(category_name) => Ok((*CATEGORIES_CACHE.get(category_name).unwrap()).to_string()),
            None => Err(Error::new(
                std::io::ErrorKind::InvalidInput,
                "Category name is required",
            )),
        }
    }

    fn parse_attributes(args: &Arguments) -> Result<Vec<String>, Error> {
        match &args.attribute_names {
            Some(attribute_names) => Ok(attribute_names
                .to_vec()
                .iter()
                .map(|attribute_name| (*ATTRIBUTES_CACHE.get(attribute_name).unwrap()).to_string())
                .collect()),
            None => Err(Error::new(
                std::io::ErrorKind::InvalidInput,
                "Attribute names are required",
            )),
        }
    }

    /// Creates the payload for the request for getting attributes.
    pub fn get_component_count_payload(
        &self,
        attribute_names: Option<Vec<String>>,
        filters: Option<HashMap<String, Vec<String>>>,
    ) -> Value {
        // If attribute is Some, then we want to put it into a Vec, otherwise an empty Vec
        let filter_map = filters.unwrap_or(HashMap::new());
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

    /// Creates the payload for the request for getting attributes.
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

    fn get_parts_payload(&self) -> Value {
        let json_data = json!({
            "operationName": "PricesViewSearch",
            "variables": {
                "country": "US",
                "currency": "USD",
                "filters": {
                    "category_id": [
                        [self.category_id],
                    ],
                },
                "in_stock_only": false,
                "limit": 100,
                "start": 0,
            },
            "query": PART_SEARCH_QUERY.to_string(),
        });
        json_data
    }

    pub async fn send_request(&self, request_type: RequestType) -> Result<Value, Error> {
        let body = match request_type {
            RequestType::Attributes => self.get_attributes_payload(),
            RequestType::Parts => self.get_parts_payload(),
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
        let headers = self.headers.clone().ok_or(Error::new(
            std::io::ErrorKind::InvalidInput,
            "Headers are required",
        ))?;
        let response = self
            .client
            .post(ENDPOINT)
            .headers(headers)
            .json(&body)
            .send()
            .await
            .expect("Failed to send request");
        let response: Value = response.json().await.expect("Failed to parse response");
        Ok(response)
    }
}
