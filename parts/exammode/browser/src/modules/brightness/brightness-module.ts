import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import {
  BacklightController,
  BacklightControllerObserver,
} from './brightness-observer';
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

      this.dispatchClientNotification('brightnessChanged', brightness);
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
    const maxBrigtnessString = await run('brightnessctl max');

    const brightness = parseInt(brightnessString.trim());
    const maxBrigtness = parseInt(maxBrigtnessString.trim());

    if (isNaN(brightness) || isNaN(maxBrigtness) || maxBrigtness === 0) {
      throw new Error('Invalid brightness values');
    }

    return Math.round((brightness / maxBrigtness) * 100);
  }

  async setBrightness(brightness: number): Promise<void> {
    if (typeof brightness !== 'number' || brightness < 0 || brightness > 100) {
      throw new Error('Brightness must be a number between 0 and 100');
    }

    await run(`brightnessctl set ${brightness}%`);
    logger.info(`Brightness set to ${brightness}%`);
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
