import { BrightnessModule } from '../../src/modules/brightness/brightness-module';
import { logger } from '../../src/utils/logger';
import { run } from '../../src/utils/shell';
import { readdir } from 'node:fs/promises';
import { mocked } from 'jest-mock';
import { watch } from 'node:fs';

jest.mock('node:fs/promises', () => ({
  readdir: jest.fn(),
}));

jest.mock('node:fs', () => ({
  watch: jest.fn(),
}));

jest.mock('../../src/utils/shell', () => ({
  run: jest.fn(),
}));

jest.mock('../../src/utils/logger', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

const mockedReaddir = mocked(readdir);
const mockedWatch = mocked(watch);
const mockedRun = mocked(run);
const mockedLogger = mocked(logger);

describe('BrightnessModule', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('should register an observer for the primary backlight controller', async () => {
    const backlightControllers = ['intel_backlight', 'acpi_video0'];
    mockedReaddir.mockResolvedValue(backlightControllers as any);

    new BrightnessModule();
    await new Promise(process.nextTick);

    expect(mockedReaddir).toHaveBeenCalledWith('/sys/class/backlight');
    expect(mockedWatch).toHaveBeenCalledWith(
      '/sys/class/backlight/intel_backlight/brightness',
      expect.any(Function)
    );
  });

  it('should handle no backlight controllers found', async () => {
    mockedReaddir.mockResolvedValue([]);

    new BrightnessModule();
    await new Promise(process.nextTick);

    expect(mockedReaddir).toHaveBeenCalledWith('/sys/class/backlight');
    expect(mockedLogger.warn).toHaveBeenCalledWith(
      'No backlight controllers found'
    );
    expect(mockedWatch).not.toHaveBeenCalled();
  });

  describe('onBacklightControllerChanged', () => {
    it('should get brightness and dispatch notification on change', async () => {
      const backlightControllers = ['intel_backlight'];
      mockedReaddir.mockResolvedValue(backlightControllers as any);
      mockedRun
        .mockResolvedValueOnce('210') // For 'brightnessctl get'
        .mockResolvedValueOnce('500'); // For 'brightnessctl max'

      const brightnessModule = new BrightnessModule();
      brightnessModule.dispatchClientNotification = jest.fn();
      await new Promise(process.nextTick);

      const watchCallback = mockedWatch.mock.calls[0]?.[1] as () =>
        | void
        | undefined;
      if (!watchCallback) {
        throw new Error('Watch callback Was not set');
      }
      watchCallback();
      await new Promise(process.nextTick);

      expect(mockedRun).toHaveBeenCalledWith('brightnessctl', ['get']);
      expect(mockedRun).toHaveBeenCalledWith('brightnessctl', ['max']);
      expect(mockedLogger.debug).toHaveBeenCalledWith(
        'Brightness changed externally: 42%'
      );

      expect(brightnessModule.dispatchClientNotification).toHaveBeenCalledWith(
        'BrightnessChanged',
        42
      );
    });

    it('should log an error if getting brightness fails', async () => {
      const backlightControllers = ['intel_backlight'];
      mockedReaddir.mockResolvedValue(backlightControllers as any);
      const brightnessError = new Error('Failed to get brightness');
      mockedRun.mockRejectedValue(brightnessError);

      const brightnessModule = new BrightnessModule();
      brightnessModule.dispatchClientNotification = jest.fn();
      await new Promise(process.nextTick);

      const watchCallback = mockedWatch.mock.calls[0]?.[1] as () =>
        | void
        | undefined;
      if (!watchCallback) {
        throw new Error('Watch callback Was not set');
      }
      watchCallback();
      await new Promise(process.nextTick);

      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to notify brightness change:',
        brightnessError
      );

      expect(
        brightnessModule.dispatchClientNotification
      ).not.toHaveBeenCalled();
    });
  });

  describe('getBrightness', () => {
    it('should return the correct brightness percentage', async () => {
      mockedRun
        .mockResolvedValueOnce('50') // For 'brightnessctl get'
        .mockResolvedValueOnce('200'); // For 'brightnessctl max'

      const brightnessModule = new BrightnessModule();
      await new Promise(process.nextTick);
      const brightness = await brightnessModule.getBrightness();

      expect(brightness).toBe(25);
      expect(mockedRun).toHaveBeenCalledWith('brightnessctl', ['get']);
      expect(mockedRun).toHaveBeenCalledWith('brightnessctl', ['max']);
    });

    it('should throw an error for invalid brightness values', async () => {
      mockedRun
        .mockResolvedValueOnce('invalid') // For 'brightnessctl get'
        .mockResolvedValueOnce('200'); // For 'brightnessctl max'

      const brightnessModule = new BrightnessModule();
      await new Promise(process.nextTick);
      await expect(brightnessModule.getBrightness()).rejects.toThrow(
        'Invalid brightness values'
      );
    });

    it('should throw an error if max brightness is 0', async () => {
      mockedRun
        .mockResolvedValueOnce('0') // For 'brightnessctl get'
        .mockResolvedValueOnce('0'); // For 'brightnessctl max'

      const brightnessModule = new BrightnessModule();
      await new Promise(process.nextTick);
      await expect(brightnessModule.getBrightness()).rejects.toThrow(
        'Invalid brightness values'
      );
    });
  });

  describe('setBrightness', () => {
    beforeEach(() => {
      // Prevent registerBacklightControllerObserver from running in these tests
      mockedReaddir.mockResolvedValue([]);
    });

    it('should set the brightness correctly', async () => {
      mockedRun.mockResolvedValueOnce('');

      const brightnessModule = new BrightnessModule();
      await new Promise(process.nextTick);
      await brightnessModule.setBrightness(50);

      expect(mockedRun).toHaveBeenCalledWith('brightnessctl', ['set', '50%']);
      expect(mockedLogger.info).toHaveBeenCalledWith('Brightness set to 50%');
    });

    it.each([
      [-1],
      [101],
      [NaN],
      ['50' as any],
      [null as any],
      [undefined as any],
    ])(
      'should throw an error for invalid brightness value: %p',
      async invalidValue => {
        const brightnessModule = new BrightnessModule();
        await new Promise(process.nextTick);
        await expect(
          brightnessModule.setBrightness(invalidValue)
        ).rejects.toThrow('Brightness must be a number between 0 and 100');
        expect(mockedRun).not.toHaveBeenCalled();
      }
    );
  });
});
