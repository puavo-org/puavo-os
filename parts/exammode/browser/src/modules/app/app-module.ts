import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import { logger } from '../../utils/logger';

export class AppModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  async getAppInfo() {
    logger.info('App information requested');
    return {
      appPlatform: 'Linux',
      appVersion: '2.0.0',
    };
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getAppInfo', this.getAppInfo.bind(this)],
    ]);
  }
}
