pub mod audit;
pub mod derive;
pub mod initialize;
pub mod operator;
pub mod organization;

use async_trait::async_trait;
use puavo_ipc::{
    AuditCommand, DaemonResponse, OperatorCommand, OrganizationCommand,
};

/// Trait for executing KPS commands
///
/// This trait allows for dependency injection and testing of command handlers
#[async_trait]
pub trait CommandExecutor: Send + Sync {
    /// Execute initialize command
    async fn execute_initialize(
        &self,
        hsm_slot: u64,
        hsm_pin: Option<String>,
        force: bool,
    ) -> DaemonResponse;

    /// Execute organization command
    async fn execute_organization(
        &self,
        command: OrganizationCommand,
    ) -> DaemonResponse;

    /// Execute derive command
    async fn execute_derive(
        &self,
        shuttle_path: Option<std::path::PathBuf>,
        operator_id: Option<String>,
        batch_size: usize,
        dry_run: bool,
    ) -> DaemonResponse;

    /// Execute audit command
    async fn execute_audit(&self, command: AuditCommand) -> DaemonResponse;

    /// Execute operator command
    async fn execute_operator(
        &self,
        command: OperatorCommand,
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
        hsm_slot: u64,
        hsm_pin: Option<String>,
        force: bool,
    ) -> DaemonResponse {
        initialize::execute(hsm_slot, hsm_pin, force).await
    }

    async fn execute_organization(
        &self,
        command: OrganizationCommand,
    ) -> DaemonResponse {
        organization::execute(command).await
    }

    async fn execute_derive(
        &self,
        shuttle_path: Option<std::path::PathBuf>,
        operator_id: Option<String>,
        batch_size: usize,
        dry_run: bool,
    ) -> DaemonResponse {
        derive::execute(shuttle_path, operator_id, batch_size, dry_run).await
    }

    async fn execute_audit(&self, command: AuditCommand) -> DaemonResponse {
        audit::execute(command).await
    }

    async fn execute_operator(
        &self,
        command: OperatorCommand,
    ) -> DaemonResponse {
        operator::execute(command).await
    }
}
