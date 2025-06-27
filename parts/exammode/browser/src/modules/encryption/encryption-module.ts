import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';

export class EncryptionModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  // eslint-disable-next-line @typescript-eslint/require-await
  async getEncryptionKey(): Promise<string> {
    return '';
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map();
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getEncryptionKey', this.getEncryptionKey.bind(this)],
    ]);
  }
}
