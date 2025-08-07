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
  async setSessionData(): Promise<void> {
    logger.warn('Session data is not implemented');
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, QueryHandler>([
      ['setSessionData', this.setSessionData.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map();
  }
}
