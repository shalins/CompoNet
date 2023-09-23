use crate::config::DEFAULT_USER_AGENT;

use clap::Parser;
use dialoguer::Input;

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
            self.px = Some(Input::new()
                .with_prompt("Enter PerimeterX key")
                .interact_text().unwrap());
        }
        if self.user_agent.is_none() {
            self.user_agent = Some(Input::new()
                .with_prompt("Enter User Agent")
                .default(DEFAULT_USER_AGENT.to_string())
                .interact_text().unwrap());
        }
        if self.category_name.is_none() {
            self.category_name = Some(Input::new()
                .with_prompt("Enter Category Name")
                .interact_text().unwrap());
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
                //self.attribute_names.push(attribute);
                attributes.push(attribute);
            }
            self.attribute_names = Some(attributes);
        }
    }
}

pub struct Cli { args: Arguments }

impl Cli {
    pub fn new() -> Self {
        let mut args = Arguments::parse();
        args.prompt_for_missing_fields();

        Self { args }
    }

    pub fn get_args(&self) -> &Arguments {
        &self.args
    }
}

