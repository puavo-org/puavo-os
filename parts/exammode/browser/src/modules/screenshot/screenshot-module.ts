import { logger } from '../../utils/logger';
import { run } from '../../utils/shell';
import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';

export class ScreenshotModule implements Module {
  // Gnome screenshot utility has clipboard mode, but it does not seem to work
  static readonly SCREENSHOT_COMMAND = 'gnome-screenshot --area --file /tmp/screenshot.png && cat /tmp/screenshot.png | xclip -i -selection clipboard -target image/png';

  dispatchClientNotification: ClientNotificationHandler = () => {};

  async takeScreenshot(): Promise<void> {
    try {
      await run(ScreenshotModule.SCREENSHOT_COMMAND);
    } catch (exception) {
      logger.error(`Failed to take screenshot: ${exception}`);
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
