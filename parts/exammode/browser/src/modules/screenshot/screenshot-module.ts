import { clipboard, type WebContents } from 'electron';
import { logger } from '../../utils/logger';
import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';

export class ScreenshotModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  constructor(private readonly contents: WebContents) {}

  async tryTakeScreenshot(
    startX: number,
    startY: number,
    endX: number,
    endY: number
  ): Promise<void> {
    const hasFiniteArea =
      Number.isFinite(startX) &&
      Number.isFinite(startY) &&
      Number.isFinite(endX) &&
      Number.isFinite(endY);

    if (!hasFiniteArea) {
      throw new Error('Expected finite screenshot area coordinates');
    }

    const x = Math.max(0, Math.min(startX, endX));
    const y = Math.max(0, Math.min(startY, endY));
    const width = Math.max(0, Math.abs(endX - startX));
    const height = Math.max(0, Math.abs(endY - startY));

    if (width === 0 || height === 0) {
      throw new Error('Expected valid screenshot area');
    }

    const image = await this.contents.capturePage({ x, y, width, height });

    if (image.isEmpty()) {
      throw new Error('Captured image was empty');
    }

    clipboard.writeImage(image);
  }

  async takeScreenshot(
    startX: number,
    startY: number,
    endX: number,
    endY: number
  ): Promise<void> {
    try {
      await this.tryTakeScreenshot(startX, startY, endX, endY);
      this.dispatchClientNotification('ScreenshotTaken', true);
    } catch (error) {
      logger.error(`Failed to take screenshot: ${error}`);
      this.dispatchClientNotification('ScreenshotTaken', false);
    }
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['takeScreenshot', this.takeScreenshot.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map();
  }
}
