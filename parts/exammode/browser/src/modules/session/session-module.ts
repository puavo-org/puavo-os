import { logger } from '../../utils/logger';
import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';

export class SessionModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  // eslint-disable-next-line @typescript-eslint/require-await
  async setSessionSecret(): Promise<void> {
    logger.warn('Session secret is not implemented');
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, QueryHandler>([
      ['setSessionSecret', this.setSessionSecret.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map();
  }
}
