use clap::Parser;
use log::debug;

use crate::config::{
    constants::DEFAULT_USER_AGENT,
    prompts::{
        prompt_for_input, ATTRIBUTE_NAME_COLOR, ATTRIBUTE_NAME_PROMPT, CATEGORY_NAME_COLOR,
        CATEGORY_NAME_PROMPT, PX_KEY_COLOR, PX_KEY_PROMPT, USER_AGENT_COLOR, USER_AGENT_PROMPT,
    },
};

#[derive(Debug)]
pub enum ArgumentType {
    Px,
    UserAgent,
    CategoryName,
    AttributeNames,
}

#[derive(Parser, Debug, Default)]
pub struct Arguments {
    pub(crate) px: Option<String>,
    pub(crate) user_agent: Option<String>,
    pub(crate) category_name: Option<String>,
    pub(crate) attribute_names: Option<Vec<String>>,
}

impl Arguments {
    fn prompt_for_missing_fields(&mut self) {
        println!();
        if self.px.is_none() {
            let input = prompt_for_input(ArgumentType::Px, PX_KEY_PROMPT, PX_KEY_COLOR, None);
            self.px = Some(input);
            debug!("PX: {:?}", self.px);
        }

        if self.user_agent.is_none() {
            let input = prompt_for_input(
                ArgumentType::UserAgent,
                USER_AGENT_PROMPT,
                USER_AGENT_COLOR,
                Some(DEFAULT_USER_AGENT),
            );
            self.user_agent = Some(input);
            debug!("User Agent: {:?}", self.user_agent);
        }

        if self.category_name.is_none() {
            let input = prompt_for_input(
                ArgumentType::CategoryName,
                CATEGORY_NAME_PROMPT,
                CATEGORY_NAME_COLOR,
                None,
            );
            self.category_name = Some(input);
            debug!("Category Name: {:?}", self.category_name);
        }

        if self.attribute_names.is_none() {
            let attributes = self.prompt_for_attribute_names();
            self.attribute_names = Some(attributes);
            debug!("Attribute Names: {:?}", self.attribute_names);
        }
    }

    pub(crate) fn prompt_user_for_new_px_key(&mut self) {
        let input = prompt_for_input(ArgumentType::Px, PX_KEY_PROMPT, PX_KEY_COLOR, None);
        self.px = Some(input);
        debug!("New PX: {:?}", self.px);
    }

    fn prompt_for_attribute_names(&self) -> Vec<String> {
        let mut attributes = Vec::new();
        loop {
            let attribute = prompt_for_input(
                ArgumentType::AttributeNames,
                ATTRIBUTE_NAME_PROMPT,
                ATTRIBUTE_NAME_COLOR,
                None,
            );
            if attribute.eq_ignore_ascii_case("done") {
                break;
            }
            attributes.push(attribute);
        }
        attributes
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
