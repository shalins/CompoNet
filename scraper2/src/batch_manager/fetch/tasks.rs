use std::{collections::VecDeque, sync::Arc};

use anyhow::{anyhow, Result};
use async_trait::async_trait;
use indicatif::ProgressBar;
use log::debug;
use tokio::{sync::RwLock, task::JoinHandle};

use crate::{
    cli::Arguments,
    config::prompts::{print_error_message, LAZY_PROGRESS_STYLE},
};

#[derive(Debug, Clone)]
pub(crate) enum TaskType {
    AttributeScrape,
    ComponentCount,
    ComponentScrape,
}

/// A trait defining the processing behavior for tasks in an asynchronous context.
///
/// This trait is designed to be implemented by types that process batches of tasks asynchronously.
/// It provides a generic interface for creating and processing tasks.
#[async_trait]
pub(crate) trait TaskProcessor {
    /// The individual task data.
    type TaskData: Clone + Sync + Send;
    /// The type of result produced by each task.
    type TaskResult: Sync + Send;
    /// The type of error that can occur while processing a task.
    type TaskError: From<anyhow::Error> + Send + Sync + 'static;

    /// Creates a task for asynchronous execution.
    ///
    /// # Arguments
    /// * `task_data` - The data required to perform the task.
    ///
    /// # Returns
    /// A `JoinHandle` that resolves to the result of the task.
    fn create_task(
        &self,
        task_data: Self::TaskData,
    ) -> JoinHandle<Result<Self::TaskResult, Self::TaskError>>;

    /// Processes a queue of tasks asynchronously.
    ///
    /// # Arguments
    /// * `task_type` - The type of task being processed.
    /// * `task_data_queue` - A queue of task data elements to be processed.
    ///
    /// # Returns
    /// A vector of results from the processed tasks.
    async fn process_tasks(
        &self,
        task_type: TaskType,
        task_data_queue: VecDeque<Self::TaskData>,
    ) -> Result<Vec<Result<Self::TaskResult, Self::TaskError>>>;
}

/// Joins a vector of asynchronous tasks and returns their results.
///
/// This function is used to await the completion of a set of tasks and collect their results.
///
/// # Arguments
/// * `current_tasks` - A vector of tuples containing `JoinHandle`s and an associated data type.
///
/// # Returns
/// A vector of results from the completed tasks.
///
/// # Errors
/// If any task fails, an error is returned in place of its result.
pub(crate) async fn join_current_tasks<T, E>(
    current_tasks: Vec<(JoinHandle<Result<T, E>>, impl Send)>,
) -> Vec<Result<T, E>>
where
    T: Sync + Send + 'static,
    E: From<anyhow::Error>,
{
    let futures: Vec<_> = current_tasks
        .into_iter()
        .map(|(handle, _)| handle)
        .collect();

    let task_results = futures::future::join_all(futures).await;

    task_results
        .into_iter()
        .map(|task_result| match task_result {
            Ok(ok_value) => ok_value,
            Err(join_error) => Err(anyhow!(join_error).into()),
        })
        .collect()
}

/// Processes a queue of tasks in batches, handling failures and retries.
///
/// This function takes a queue of tasks and processes them in batches up to a specified size.
/// It also handles task failures by prompting for user intervention and retrying failed tasks.
///
/// # Arguments
/// * `task_type` - The type of task being processed.
/// * `processor` - The task processor implementing the `TaskProcessor` trait.
/// * `task_data_queue` - A queue of task data to be processed.
/// * `batch_size` - The maximum number of tasks to process in a single batch.
/// * `args` - Shared application arguments, used for user prompts.
///
/// # Returns
/// A vector of results from all processed tasks.
///
/// # Errors
/// Returns an error if any task in the batch fails after retrying.
pub(crate) async fn process_tasks_helper<T>(
    processor: &T,
    task_type: TaskType,
    task_data_queue: VecDeque<T::TaskData>,
    batch_size: usize,
    args: Arc<RwLock<Arguments>>,
) -> Result<Vec<Result<T::TaskResult, T::TaskError>>>
where
    T: TaskProcessor + Sync + 'static,
{
    let mut results = Vec::new();
    let mut tasks = Vec::new();
    let mut task_data_queue = task_data_queue;

    let total_tasks = task_data_queue.len();
    let progress_bar = ProgressBar::new(total_tasks as u64);
    progress_bar.set_style(LAZY_PROGRESS_STYLE.clone());

    while !task_data_queue.is_empty() {
        if let Some(task_data) = task_data_queue.pop_front() {
            let task = processor.create_task(task_data.clone());
            tasks.push((task, task_data));
        }

        if tasks.len() >= batch_size || task_data_queue.is_empty() {
            debug!("Tasks left: {}", task_data_queue.len());
            progress_bar.set_position((total_tasks - task_data_queue.len()) as u64);

            let associated_task_data: Vec<_> = tasks
                .iter()
                .map(|(_, task_data)| task_data.clone())
                .collect();
            let batch_results = join_current_tasks(std::mem::take(&mut tasks)).await;
            let batch_results_with_task_data: Vec<_> = batch_results
                .into_iter()
                .zip(associated_task_data)
                .collect();

            let failed_tasks: Vec<_> = batch_results_with_task_data
                .iter()
                .filter_map(|(res, task_data)| {
                    if res.is_err() {
                        Some(task_data.clone())
                    } else {
                        None
                    }
                })
                .collect();

            if !failed_tasks.is_empty() {
                print_error_message(&task_type, failed_tasks.len());
                args.write().await.prompt_user_for_new_px_key();
                task_data_queue.extend(failed_tasks.into_iter()); // FIX THIS
            } else {
                results.extend(
                    batch_results_with_task_data
                        .into_iter()
                        .map(|(result, _)| result),
                );
            }
        }
    }

    progress_bar.finish_with_message("Processing complete");
    Ok(results)
}