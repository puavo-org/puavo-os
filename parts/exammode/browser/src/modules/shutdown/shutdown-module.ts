import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import { logger } from '../../utils/logger';
import { systemBus } from 'dbus-next';

export type ShutdownCallback = () => void;

export class ShutdownModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};
  shutdownCallback: ShutdownCallback;

  constructor(shutdownCallback: ShutdownCallback) {
    this.shutdownCallback = shutdownCallback;
  }

  async shutdown(): Promise<void> {
    try {
      try {
        this.shutdownCallback();
      } catch (error) {
        logger.error('Error occurred during shutdown callback:', error);
      }

      const bus = systemBus();

      const proxyObject = await bus.getProxyObject(
        'org.puavo.Exam',
        '/exammode'
      );
      const examInterface = proxyObject.getInterface('org.puavo.Exam.exammode');

      examInterface['QuitSession']?.();
    } catch (error) {
      logger.error('Failed to quit session via DBus:', error);
    } finally {
      process.exit(0);
    }
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['shutdown', this.shutdown.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map();
  }
}
