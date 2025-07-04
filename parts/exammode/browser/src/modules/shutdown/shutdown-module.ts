import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import { logger } from '../../utils/logger';
import { systemBus } from 'dbus-next';

export class ShutdownModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  async shutdown(): Promise<void> {
    const bus = systemBus();

    try {
      const proxyObject = await bus.getProxyObject(
        'org.puavo.Exam',
        '/exammode'
      );
      const examInterface = proxyObject.getInterface('org.puavo.Exam.exammode');

      await examInterface['QuitSession']?.();
    } catch (error) {
      logger.error('Failed to quit session via DBus:', error);
    }

    logger.info('Exiting the application...');
    process.exit(0);
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
