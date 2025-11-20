import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';

export class KeyboardModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  constructor() { }
  
  async getKeyboardLayouts(): Promise<string[]> {
    return [];
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>();
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getKeyboardLayouts', this.getKeyboardLayouts.bind(this)],
    ]);
  }
}
