use futures::future::join_all;
use std::sync::Arc;

use crate::cli::Cli;
use crate::request_sender::{RequestSender, RequestType};

pub struct BatchManager {
    batch_size: usize,
}

impl BatchManager {
    pub fn new(batch_size: usize) -> Self {
        Self { batch_size }
    }

    // function that handles the logic for grabbing all the numbers of pages for each of the attributes we need.
    pub async fn grab_component_count(&self, attributes: Vec<String>) {
        //let attributes =
    }

    pub async fn run(&self) {
        let cli = Cli::new();
        let args = cli.get_args();
        let request_sender = Arc::new(RequestSender::new(args));

        //panic!("args: {:?}", &args);
        let tasks: Vec<_> = (0..1)
            .map(|_| {
                let request_sender = request_sender.clone();
                tokio::spawn(async move { request_sender.send_request(RequestType::Parts).await })
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
