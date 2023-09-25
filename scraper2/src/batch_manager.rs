use futures::future::join_all;
use std::collections::HashMap;
use std::sync::Arc;
use std::thread::current;
use std::vec;

use crate::cli::Cli;
use crate::request_sender::{RequestSender, RequestType};
use crate::response_handler::ResponseHandler;

pub struct BatchManager {
    batch_size: usize,
}

impl BatchManager {
    pub fn new(batch_size: usize) -> Self {
        Self { batch_size }
    }

    // function that handles the logic for grabbing all the numbers of pages for each of the attributes we need.
    pub async fn grab_component_count(&self) {
        let cli = Cli::new();
        let args = cli.get_args();
        let request_sender = Arc::new(RequestSender::new(args));
        let response_handler = Arc::new(ResponseHandler::new());
        let max_tasks = 100;

        // first get the total list of attributes
        let attributes_response = request_sender
            .clone()
            .send_request(RequestType::Attributes)
            .await;
        //println!("attributes_response: {:?}", attributes_response);
        let bucket_map = response_handler
            .clone()
            .extract_buckets(
                attributes_response.unwrap(),
                request_sender.get_attribute_ids().unwrap(),
            )
            .await
            .unwrap();
        //println!("bucket_map: {:?}", bucket_map);

        // parse them into a map of attribute id to the list of buckets.

        match bucket_map.buckets.len() {
            1 => {
                // just reformat the bucket map that was returned and that's it.
            }
            2 => {
                // using the bucket map, go through all the values in the first category and use it to filter + grab the second category.
                let first_attribute_key = request_sender.get_attribute_ids().unwrap()[0].clone();
                let first_attribute_bucket =
                    bucket_map.buckets.get(&first_attribute_key).unwrap().iter();
                let last_attribute_key = Some(vec![request_sender
                    .get_attribute_ids()
                    .unwrap()
                    .last()
                    .unwrap()
                    .clone()]);
                for bucket in first_attribute_bucket {
                    let mut filters = HashMap::new();
                    filters.insert(
                        first_attribute_key.clone(),
                        vec![bucket
                            .float_value
                            .clone()
                            .unwrap_or(bucket.display_value.clone())],
                    );
                    let response = request_sender
                        .clone()
                        .send_request(RequestType::ComponentCount {
                            attributes: last_attribute_key.to_owned(),
                            filters: Some(filters),
                        })
                        .await
                        .unwrap();
                    // println!(
                    //     "For bucket key: {:?} {:?}, \n response is: {:?}",
                    //     bucket.display_value, bucket.float_value, response
                    // );
                    let current_attributes = vec![bucket.display_value.clone()];
                    let combinations = response_handler
                        .extract_filter_combinations(response, current_attributes)
                        .await
                        .unwrap();
                    println!("combinations: {:?}", combinations);
                }
            }
            _ => {}
        }
    }

    pub async fn run(&self) {
        let cli = Cli::new();
        let args = cli.get_args();
        let request_sender = Arc::new(RequestSender::new(args));

        //panic!("args: {:?}", &args);
        let tasks: Vec<_> = (0..1)
            .map(|_| {
                let request_sender = request_sender.clone();
                tokio::spawn(
                    async move { request_sender.send_request(RequestType::Attributes).await },
                )
            })
            .collect();

        let results = join_all(tasks).await;

        let mut any_failed = false;
        for result in results {
            match result {
                Ok(Ok(json)) => {
                    println!("Request succeeded: {}", json);
                }
                Ok(Err(e)) => {
                    eprintln!("Request failed: {}", e);
                    any_failed = true;
                }
                Err(e) => {
                    eprintln!("Request failed: {}", e);
                    any_failed = true;
                }
            }
        }

        if any_failed {
            println!("Some requests failed");
        } else {
            println!("All requests succeeded");
        }
    }
}
