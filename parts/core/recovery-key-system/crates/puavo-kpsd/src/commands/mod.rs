pub mod initialize;
pub mod organization;
pub mod recovery;

use crate::context::DaemonContext;
use async_trait::async_trait;
use puavo_ipc::{DaemonResponse, OrganizationCommand};
use std::{path::PathBuf, sync::Arc};

/// Trait for executing KPS commands
///
/// This trait allows for dependency injection and testing of command handlers
#[async_trait]
pub trait CommandExecutor: Send + Sync {
    /// Execute initialize command
    async fn execute_initialize(
        &self,
        context: Arc<DaemonContext>,
        hsm_slot: u64,
        hsm_pin: Option<String>,
        force: bool,
    ) -> DaemonResponse;

    /// Execute organization command
    async fn execute_organization(
        &self,
        context: Arc<DaemonContext>,
        command: OrganizationCommand,
    ) -> DaemonResponse;

    /// Execute generate command
    async fn execute_generate(
        &self,
        context: Arc<DaemonContext>,
        operator_id: Option<String>,
        organization_id: String,
        serial_numbers: Vec<String>,
        recovery_key_files: Vec<PathBuf>,
    ) -> DaemonResponse;

    /// Execute unwrap command
    async fn execute_unwrap(
        &self,
        context: Arc<DaemonContext>,
        operator_id: Option<String>,
        recovery_bundle_paths: Vec<PathBuf>,
    ) -> DaemonResponse;
}

/// Default implementation of command executor
pub struct DefaultCommandExecutor;

impl DefaultCommandExecutor {
    pub fn new() -> Self {
        Self
    }
}

#[async_trait]
impl CommandExecutor for DefaultCommandExecutor {
    async fn execute_initialize(
        &self,
        _context: Arc<DaemonContext>,
        hsm_slot: u64,
        hsm_pin: Option<String>,
        force: bool,
    ) -> DaemonResponse {
        initialize::execute(hsm_slot, hsm_pin, force).await
    }

    async fn execute_organization(
        &self,
        context: Arc<DaemonContext>,
        command: OrganizationCommand,
    ) -> DaemonResponse {
        let hsm_session = context.hsm_session.lock().await;
        organization::execute(&hsm_session, command)
    }

    async fn execute_generate(
        &self,
        context: Arc<DaemonContext>,
        operator_id: Option<String>,
        organization_id: String,
        serial_numbers: Vec<String>,
        recovery_key_files: Vec<PathBuf>,
    ) -> DaemonResponse {
        let hsm_session = context.hsm_session.lock().await;
        recovery::execute_generate(
            &hsm_session,
            operator_id,
            organization_id,
            serial_numbers,
            recovery_key_files,
        )
    }

    async fn execute_unwrap(
        &self,
        context: Arc<DaemonContext>,
        operator_id: Option<String>,
        recovery_bundle_paths: Vec<PathBuf>,
    ) -> DaemonResponse {
        let hsm_session = context.hsm_session.lock().await;
        recovery::execute_unwrap(
            &hsm_session,
            operator_id,
            recovery_bundle_paths,
        )
    }
}
