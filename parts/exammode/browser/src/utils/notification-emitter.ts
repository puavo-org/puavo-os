import { logger } from './logger';

export type NotificationEmitterHandler = (self: any, data: string) => void;

export class NotificationEmitter {
  private readonly listeners: Map<string, Set<NotificationEmitterHandler>> =
    new Map();

  addEventListener(type: string, handler: NotificationEmitterHandler): void {
    if (!this.listeners.has(type)) {
      this.listeners.set(type, new Set());
    }
    this.listeners.get(type)!.add(handler);
  }

  removeEventListener(type: string, handler: NotificationEmitterHandler): void {
    if (this.listeners.has(type)) {
      this.listeners.get(type)!.delete(handler);
    }
  }

  emit(type: string, data: string): void {
    const handlers = this.listeners.get(type);

    if (!handlers) {
      logger.warn(`No handlers registered for event type: ${type}`);
      return;
    }

    for (const handler of handlers) {
      (async handler => {
        try {
          handler(this, data);
        } catch (error) {
          logger.error('Error in event handler:', error);
        }
      })(handler);
    }
  }
}
