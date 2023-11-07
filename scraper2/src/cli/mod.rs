use crate::config::constants::DEFAULT_USER_AGENT;

use clap::Parser;
use dialoguer::Input;
use log::debug;

#[derive(Parser, Debug, Default)]
pub struct Arguments {
    pub px: Option<String>,
    pub user_agent: Option<String>,
    pub category_name: Option<String>,
    pub attribute_names: Option<Vec<String>>,
}

impl Arguments {
    fn prompt_for_missing_fields(&mut self) {
        if self.px.is_none() {
            self.px = Some(
                Input::new()
                    .with_prompt("Enter PerimeterX key")
                    .interact_text()
                    .unwrap(),
            );
            debug!("PX: {:?}", self.px);
        }
        if self.user_agent.is_none() {
            self.user_agent = Some(
                Input::new()
                    .with_prompt("Enter User Agent")
                    .default(DEFAULT_USER_AGENT.to_string())
                    .interact_text()
                    .unwrap(),
            );
            debug!("User Agent: {:?}", self.user_agent);
        }
        if self.category_name.is_none() {
            self.category_name = Some(
                Input::new()
                    .with_prompt("Enter Category Name")
                    .interact_text()
                    .unwrap(),
            );
            debug!("Category Name: {:?}", self.category_name);
        }
        if self.attribute_names.is_none() {
            let mut attributes = Vec::new();
            loop {
                let attribute: String = Input::new()
                    .with_prompt("Enter Attribute Name (enter 'done' when finished)")
                    .interact_text()
                    .unwrap();
                if attribute == "done" {
                    break;
                }
                attributes.push(attribute);
            }
            self.attribute_names = Some(attributes);
            debug!("Attribute Names: {:?}", self.attribute_names);
        }
    }

    pub fn prompt_user_for_new_px_key(&mut self) {
        self.px = Some(
            Input::new()
                .with_prompt("Enter a new PerimeterX key")
                .interact_text()
                .unwrap(),
        );
    }
}

pub struct Cli {}

impl Cli {
    pub fn prompt() -> Arguments {
        let mut args = Arguments::parse();
        args.prompt_for_missing_fields();
        args
    }
}
