use futures::future::join_all;
use reqwest;
use serde::Serialize;
use serde_json::{to_string_pretty, Value};
use tokio::time::{sleep, Duration};

const URL: &'static str = "https://octopart.com/api/v4/internal";

#[derive(Clone, Debug, Serialize)]
struct JsonRequest {
    operation_name: String,
    variables: Variables,
    query: String,
}

#[derive(Clone, Debug, Serialize)]
struct Variables {
    attribute_names: Vec<String>,
    currency: String,
    filters: Filters,
    in_stock_only: bool,
    q: String,
}

#[derive(Clone, Debug, Serialize)]
struct Filters {
    category_id: Vec<String>,
    capacitance: Vec<String>,
    voltagerating_dc_: Vec<String>,
    dielectric: Vec<String>,
}

#[tokio::main]
async fn main() -> Result<(), reqwest::Error> {
    // Initialize the client
    let client = reqwest::Client::new();

    // Set up the cookies
    let mut headers = reqwest::header::HeaderMap::new();
    headers.insert(
    reqwest::header::USER_AGENT,
    reqwest::header::HeaderValue::from_static("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36"),
);
    headers.insert(
    reqwest::header::COOKIE,
    reqwest::header::HeaderValue::from_str("_px=y3JUstXwVww6JVBBBBV5HBSmPfaeUrJVOiqLi/2VStsM6nUSUEyP2aYy90uyparCkrfB8Mr2zi85tyZ6F3SMKg==:1000:qU6/I4PdhT0ih5rh7N39uHUyb9YewovRTeu/Du9YFXK6McJ/vdxBIiNjkJcarigJmKO0RcWMXKPTV0biXl5W8EG/8UAFSLsVrb8iYRlCzcea0wiHhAd5L9CltRQhltcewpuE83i7RNFz0V3R6j/kaXSvoY9ft3Rc8At6UkjyYfNg8KMMZBowM3p2s3xZf12Cl9JjPG2PLd7Gfc1T2GJgfP269DuJUMXKM4wKfFvwciOLgapZ5oGveJw8qO3QcYDDPjNdUjRXMdg5i5qGp86WeQ==").unwrap(),
);

    // Create the JSON payload
    let json_data = JsonRequest {
        operation_name: "FilterModalSearch".to_string(),
        variables: Variables {
            attribute_names: vec!["dielectric".to_string()],
            currency: "USD".to_string(),
            filters: Filters {
                category_id: vec!["6332".to_string()],
                capacitance: vec!["1e-9".to_string()],
                voltagerating_dc_: vec!["50".to_string()],
                dielectric: vec!["C0G".to_string()],
            },
            in_stock_only: false,
            q: "".to_string(),
        },
        query: "query FilterModalSearch($attribute_names: [String!]!, $currency: String!, $filters: Map, $in_stock_only: Boolean, $q: String) {\n  search(currency: $currency, filters: $filters, in_stock_only: $in_stock_only, q: $q) {\n    hits\n    spec_aggs(attribute_names: $attribute_names, size: 100) {\n      attribute {\n        group\n        id\n        name\n        shortname\n        __typename\n      }\n      buckets {\n        count\n        display_value\n        float_value\n        __typename\n      }\n      display_max\n      display_min\n      max\n      min\n      __typename\n    }\n    __typename\n  }\n}\n".to_string(),
    };

    async fn send_request<'a>(
        client: &'a reqwest::Client,
        headers: &'a reqwest::header::HeaderMap,
        json_data: &'a JsonRequest,
    ) -> Result<Value, reqwest::Error> {
        // Make the HTTP POST request
        let response = client
            .post(URL)
            .headers(headers.clone())
            .json(&json_data)
            .send()
            .await?;

        let json_response: Value = response.json().await?;
        return Ok(json_response);
    }

    for _ in 0..100 {
        let tasks: Vec<_> = (0..1000)
            .map(|_| {
                let client_clone = client.clone();
                let headers_clone = headers.clone();
                let json_data_clone = json_data.clone();
                tokio::spawn(async move {
                    send_request(&client_clone, &headers_clone, &json_data_clone).await
                })
            })
            .collect();

        let results = join_all(tasks).await;

        let mut any_failed = false;
        for result in results {
            match result {
                Ok(Ok(_)) => {},
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

        sleep(Duration::from_secs(3)).await;
    }

    Ok(())
}
