import type { NotificationBody, WindowsKioskAPI } from '../types/types';
import { NotificationEmitter } from '../utils/notification-emitter';
import { logger } from '../utils/logger';
import { ipcRenderer } from 'electron';

const notifyDispatchOverrideTable = new Map<string, string>([
  ['ActiveAudioDeviceChanged', 'changeActiveAudioDevice'],
  ['AudioDeviceVolumeChanged', 'changeAudioDeviceVolume'],
  ['BrightnessChanged', 'setBrightness'],
  ['ScreenshotRequested', 'takeScreenshot'],
  ['SessionChanged', 'setSessionData'],
  ['ShutdownRequested', 'shutdown'],
  ['StartSurveillance', 'startSurveillance'],
]);

const queryDispatchOverrideTable = new Map<string, string>([]);

export class KioskAPI extends NotificationEmitter implements WindowsKioskAPI {
  async Notify(body: string): Promise<void> {
    const { Type, Body } = JSON.parse(body) as NotificationBody;

    const handlerName = notifyDispatchOverrideTable.get(Type) ?? Type;
    logger.debug(
      `Handling notification of type ${Type} with handler ${handlerName}`
    );

    await ipcRenderer.invoke(
      handlerName,
      // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
      ...(Array.isArray(Body) ? Body : [Body])
    );
  }

  async Query(body: string): Promise<string> {
    const { Type, Body } = JSON.parse(body) as NotificationBody;

    const handlerName = queryDispatchOverrideTable.get(Type) ?? Type;
    logger.debug(`Handling query of type ${Type} with handler ${handlerName}`);

    try {
      // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
      const result = await ipcRenderer.invoke(
        handlerName,
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        ...(Array.isArray(Body) ? Body : [Body])
      );
      return JSON.stringify(result);
    } catch (error) {
      logger.error(`Error handling query for type ${Type}:`, error);
      throw error;
    }
  }
}
