export type ClientNotificationHandler = (type: string, body: any) => void;
export type NotifyHandler = (...args: any[]) => Promise<void>;
export type QueryHandler = (...args: any[]) => Promise<any>;

export interface Module {
  dispatchClientNotification: ClientNotificationHandler;
  getNotifyHandlerDefinitions(): Map<string, NotifyHandler>;
  getQueryHandlerDefinitions(): Map<string, QueryHandler>;
}
