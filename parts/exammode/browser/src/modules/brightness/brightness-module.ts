import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import {
  BacklightController,
  BacklightControllerObserver,
} from './backlight-controller';
import { logger } from '../../utils/logger';
import { run } from '../../utils/shell';

export class BrightnessModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  constructor() {
    void this.registerBacklightControllerObserver();
  }

  async onBacklightControllerChanged(): Promise<void> {
    try {
      const brightness = await this.getBrightness();
      logger.debug(`Brightness changed externally: ${brightness}%`);

      this.dispatchClientNotification('BrightnessChanged', brightness);
    } catch (exception) {
      logger.error('Failed to notify brightness change:', exception);
    }
  }

  async registerBacklightControllerObserver(): Promise<void> {
    const backlightControllers = await BacklightController.getAll();
    const primaryBacklightController = backlightControllers[0];

    if (!primaryBacklightController) {
      logger.warn('No backlight controllers found');
      return;
    }

    logger.debug(`Backlight controller: ${primaryBacklightController.path}`);

    const primaryBacklightControllerObserver = new BacklightControllerObserver(
      this.onBacklightControllerChanged.bind(this)
    );

    primaryBacklightControllerObserver.observe(primaryBacklightController);
  }

  async getBrightness(): Promise<number> {
    const brightnessString = await run('brightnessctl get');
    const maxBrightnessString = await run('brightnessctl max');

    const brightness = parseInt(brightnessString.trim());
    const maxBrightness = parseInt(maxBrightnessString.trim());

    if (isNaN(brightness) || isNaN(maxBrightness) || maxBrightness === 0) {
      throw new Error('Invalid brightness values');
    }

    return Math.round((brightness / maxBrightness) * 100);
  }

  async setBrightness(brightness: number): Promise<void> {
    if (typeof brightness !== 'number' || brightness < 0 || brightness > 100) {
      throw new Error('Brightness must be a number between 0 and 100');
    }

    // do not let brightness go below 3, because on some hosts/displays
    // the display can go so dark that nothing can be seen
    const limited_brightness = Math.max(3, brightness);

    await run(`brightnessctl set ${limited_brightness}%`);
    logger.info(`Brightness set to ${limited_brightness}%`);
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['setBrightness', this.setBrightness.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getBrightness', this.getBrightness.bind(this)],
    ]);
  }
}
