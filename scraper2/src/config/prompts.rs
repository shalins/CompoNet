use std::fmt::Write;

use colored::Colorize;
use dialoguer::Input;
use indicatif::{ProgressState, ProgressStyle};
use once_cell::sync::Lazy;

use crate::cli::ArgumentType;

pub(crate) static LAZY_PROGRESS_STYLE: Lazy<ProgressStyle> = Lazy::new(|| {
    ProgressStyle::with_template("{spinner:.bold.green} [{elapsed_precise:.bold.white}] [{wide_bar:.bold.cyan/blue}] {count:.bold.white}/{total_count:.bold.white} ({eta:.bold.magenta})")
        .unwrap()
        .with_key("eta", |state: &ProgressState, w: &mut dyn Write| write!(w, "{:.1}s", state.eta().as_secs_f64()).unwrap())
        .with_key("count", |state: &ProgressState, w: &mut dyn Write| write!(w, "{}", state.pos()).unwrap())
        .with_key("total_count", |state: &ProgressState, w: &mut dyn Write| write!(w, "{}", state.len().unwrap_or_default()).unwrap())
        .progress_chars("#>-")
});

pub const PX_KEY_PROMPT: &str = "🔑  Enter PerimeterX key:";
pub const USER_AGENT_PROMPT: &str = "🌐  Enter User Agent:";
pub const CATEGORY_NAME_PROMPT: &str = "📁  Enter Category Name:";
pub const ATTRIBUTE_NAME_PROMPT: &str = "🔖  Enter Attribute Name (enter 'done' when finished):";
pub const FILE_OVERWRITE_PROMPT: &str = "💾  File already exists. Overwrite? (Y/N):";

pub const PX_KEY_COLOR: colored::Color = colored::Color::Cyan;
pub const USER_AGENT_COLOR: colored::Color = colored::Color::Green;
pub const CATEGORY_NAME_COLOR: colored::Color = colored::Color::Blue;
pub const ATTRIBUTE_NAME_COLOR: colored::Color = colored::Color::Magenta;
pub const FILE_OVERWRITE_COLOR: colored::Color = colored::Color::Yellow;

pub(crate) fn prompt_for_yn(
    prompt_message: &str,
    color: colored::Color,
    default: Option<&str>,
) -> String {
    println!();
    println!("\n{}", prompt_message.bold().color(color));
    let mut input = Input::new();
    if let Some(default_value) = default {
        input.default(default_value.to_string());
    }
    input
        .interact_text()
        .unwrap_or_else(|_| panic!("Failed to read Y/N. Please ensure valid input."))
}

pub(crate) fn prompt_for_input(
    input_type: ArgumentType,
    prompt_message: &str,
    color: colored::Color,
    default: Option<&str>,
) -> String {
    println!("\n{}", prompt_message.bold().color(color));
    let mut input = Input::new();
    if let Some(default_value) = default {
        input.default(default_value.to_string());
    }
    input.interact_text().unwrap_or_else(|_| {
        panic!(
            "Failed to read {:?}. Please ensure valid input.",
            input_type,
        )
    })
}

pub fn print_info_message(message: &str, is_success: bool) {
    let emoji = if is_success { "✅" } else { "🛠️ " };
    let formatted_message = format!("\n{}  {}", emoji, message).bold().white();
    println!("{}", formatted_message);
}

pub fn print_error_message(error: &impl std::fmt::Debug) {
    let formatted_message = format!("\n⚠️   Error: {:?}", error).bold().yellow();
    eprintln!("{}", formatted_message);
}

pub fn print_task_error_message(task_type: &impl std::fmt::Debug, failed_count: usize) {
    let formatted_message = format!(
        "\n⚠️   Error: Task `{:?}` had {:?} failed request(s).",
        task_type, failed_count
    )
    .bold()
    .yellow();
    eprintln!("{}", formatted_message);
}
