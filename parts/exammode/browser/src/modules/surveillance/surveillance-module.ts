import { logger } from '../../utils/logger';
import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';

export class SurveillanceModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  // eslint-disable-next-line @typescript-eslint/require-await
  async startSurveillance(): Promise<void> {
    logger.warn('Surveillance is not implemented');
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['startSurveillance', this.startSurveillance.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map();
  }
}
