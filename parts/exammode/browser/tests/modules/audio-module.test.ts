import { PulseAudioEventObserver } from '../../src/modules/audio/pulse-audio-event-observer';
import { AudioModule } from '../../src/modules/audio/audio-module';
import type { PulseAudioSink } from '../../src/types/types';
import { logger } from '../../src/utils/logger';
import { run } from '../../src/utils/shell';
import { mocked } from 'jest-mock';

jest.mock('../../src/modules/audio/pulse-audio-event-observer');
jest.mock('../../src/utils/shell');
jest.mock('../../src/utils/logger', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

const mockedRun = mocked(run);
const mockedLogger = mocked(logger);
const mockedPulseAudioEventObserver = mocked(PulseAudioEventObserver);

const mockSink1: PulseAudioSink = {
  name: 'sink1',
  description: 'Speaker',
  mute: false,
  state: 'RUNNING',
  channel_map: 'front-left,front-right',
  volume: {
    'front-left': {
      value: 32768,
      value_percent: '50%',
      db: '-18.06 dB',
    },
  },
  properties: {
    'device.product.name': 'Internal Speakers',
  },
};

const mockSink2: PulseAudioSink = {
  name: 'sink2',
  description: 'Headphones',
  mute: true,
  state: 'IDLE',
  channel_map: 'front-left,front-right',
  volume: {
    'front-left': {
      value: 49152,
      value_percent: '75%',
      db: '-6.02 dB',
    },
  },
  properties: {
    'device.product.name': 'USB Headset',
  },
};

const mockSink3: PulseAudioSink = {
  name: 'sink3',
  description: 'Another Device',
  mute: false,
  state: 'RUNNING',
  channel_map: 'invalid-channel-name',
  volume: {
    'front-left': {
      value: 65536,
      value_percent: '100%',
      db: '0 dB',
    },
  },
  properties: {
    'device.product.name': 'Some other device',
  },
};

describe('AudioModule', () => {
  let audioModule: AudioModule;
  let onAudioEventCallback: (event: any) => Promise<void>;

  beforeEach(async () => {
    jest.clearAllMocks();
    mockedRun.mockResolvedValueOnce('');

    mockedPulseAudioEventObserver.mockImplementation(
      (callback: (event: any) => Promise<void>) => {
        onAudioEventCallback = callback;
        return {
          observe: jest.fn(),
        } as any;
      }
    );
    audioModule = new AudioModule();
    audioModule.dispatchClientNotification = jest.fn();

    await new Promise(process.nextTick);
  });

  describe('constructor', () => {
    it('should log an error if unloading stream restore module fails', async () => {
      mockedRun.mockClear();
      const error = new Error('Failed to unload');
      mockedRun.mockRejectedValue(error); // For: 'pactl unload-module'

      new AudioModule();
      await new Promise(process.nextTick);

      expect(mockedRun).toHaveBeenCalledWith(
        'pactl unload-module module-stream-restore'
      );
      expect(mockedLogger.error).toHaveBeenCalledWith(
        "Failed to unload 'module-stream-restore' from PulseAudio:",
        error
      );
    });

    it('should log an error if registering audio event observer fails', () => {
      const observerInstance = audioModule.audioEventObserver;
      const error = new Error('Observer failed');
      (observerInstance.observe as unknown as jest.Mock).mockImplementation(
        () => {
          throw error;
        }
      );

      audioModule.registerAudioEventObserver();

      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to register audio event observer:',
        error
      );
    });

    it('should log an error if getDefaultSinkName fails in notifier', async () => {
      mockedRun.mockClear();
      const error = new Error('Failed to get default sink');
      mockedRun.mockRejectedValue(error); // For: 'pactl get-default-sink'

      audioModule.activeDeviceChangeNotifier.checkAndNotify();
      await new Promise(process.nextTick);

      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to get default sink name:',
        error
      );
    });

    it('should unload stream restore module', () => {
      expect(mockedRun).toHaveBeenCalledWith(
        'pactl unload-module module-stream-restore'
      );
    });

    it('should register audio event observer', async () => {
      const observerInstance = audioModule.audioEventObserver;
      expect(observerInstance).toBeDefined();
      expect(observerInstance?.observe).toHaveBeenCalled();
    });
  });

  describe('onAudioEvent', () => {
    it('should log an error if onSinkAddedOrRemoved fails', async () => {
      const error = new Error('Notify failed');
      jest.spyOn(audioModule, 'onSinkAddedOrRemoved').mockRejectedValue(error);

      await onAudioEventCallback({ event: 'new', on: 'sink' });

      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to process audio event:',
        error
      );
    });

    it('should notify on new sink event', async () => {
      mockedRun.mockResolvedValue('[]');
      await onAudioEventCallback({ event: 'new', on: 'sink' });
      expect(audioModule.dispatchClientNotification).toHaveBeenCalledWith(
        'AudioDevicesChanged',
        expect.any(Array)
      );
    });

    it('should notify on remove sink event', async () => {
      mockedRun.mockResolvedValue('[]');
      await onAudioEventCallback({ event: 'remove', on: 'sink' });
      expect(audioModule.dispatchClientNotification).toHaveBeenCalledWith(
        'AudioDevicesChanged',
        expect.any(Array)
      );
    });

    it('should not notify on other events', async () => {
      await onAudioEventCallback({ event: 'change', on: 'sink' });
      await onAudioEventCallback({ event: 'new', on: 'client' });
      expect(audioModule.dispatchClientNotification).not.toHaveBeenCalled();
    });
  });

  describe('notifyActiveDeviceChanged', () => {
    it('should log an error for empty device ID', async () => {
      await audioModule.notifyActiveDeviceChanged('');
      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Received empty active device ID'
      );
    });

    it('should not dispatch notification if device not found', async () => {
      mockedRun.mockResolvedValue(JSON.stringify([mockSink1]));
      await audioModule.notifyActiveDeviceChanged('non-existent-sink');
      expect(audioModule.dispatchClientNotification).not.toHaveBeenCalled();
    });
  });

  describe('getAudioDevices', () => {
    it('should return sorted audio devices', async () => {
      mockedRun
        .mockResolvedValueOnce(
          JSON.stringify([mockSink1, mockSink3, mockSink2])
        )
        .mockResolvedValueOnce('sink1');

      const devices = await audioModule.getAudioDevices();

      expect(devices).toHaveLength(3);
      expect(devices[0]?.displayName).toBe('Another Device');
      expect(devices[1]?.displayName).toBe('Headphones');
      expect(devices[2]?.displayName).toBe('Speaker');
      expect(devices.find(device => device.id === 'sink1')?.active).toBe(true);
      expect(devices.find(device => device.id === 'sink2')?.active).toBe(false);
      expect(devices.find(device => device.id === 'sink3')?.active).toBe(false);
    });

    it('should handle invalid display names', () => {
      const sinkWithInvalidNames: PulseAudioSink = {
        ...mockSink1,
        description: '',
        properties: { 'device.product.name': '(null)' },
        name: 'basic-audio-device',
      };
      const device = audioModule.createOutputDeviceFromSink(
        sinkWithInvalidNames,
        ''
      );
      expect(device.displayName).toBe('basic-audio-device');
    });

    it('should use fallback display name if all names are invalid', () => {
      const sinkWithNoValidName: PulseAudioSink = {
        ...mockSink1,
        description: ' ',
        properties: { 'device.product.name': '' },
        name: '(null)',
      };
      const device = audioModule.createOutputDeviceFromSink(
        sinkWithNoValidName,
        ''
      );
      expect(device.displayName).toBe(AudioModule.FALLBACK_DISPLAY_NAME);
    });
  });

  describe('getSinkVolume', () => {
    it('should return 100 if channel map is empty', () => {
      const sinkWithEmptyChannelMap = { ...mockSink1, channel_map: '' };
      const volume = audioModule.getSinkVolume(sinkWithEmptyChannelMap);
      expect(volume).toBe(100);
      expect(mockedLogger.error).toHaveBeenCalledWith(
        'No channels found for sink:',
        'sink1'
      );
    });

    it('should return 100 if channel name is invalid', () => {
      const sinkWithInvalidChannelName = {
        ...mockSink1,
        channel_map: '(null)',
        volume: {},
      };
      const volume = audioModule.getSinkVolume(sinkWithInvalidChannelName);
      expect(volume).toBe(100);
      expect(mockedLogger.error).toHaveBeenCalledWith(
        "Invalid channel name '(null)' for sink 'sink1'"
      );
    });

    it('should return 100 if volume info is missing', () => {
      const sinkWithMissingVolume = { ...mockSink1, volume: {} };
      const volume = audioModule.getSinkVolume(sinkWithMissingVolume);
      expect(volume).toBe(100);
      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to get volume for sink:',
        'sink1'
      );
    });
  });

  describe('onSinkAddedOrRemoved', () => {
    it('should log an error if audioDevicesChangeNotifier fails', async () => {
      const error = new Error('Notifier error');
      audioModule.audioDevicesChangeNotifier.checkAndNotify = jest
        .fn()
        .mockRejectedValue(error);

      await audioModule.onSinkAddedOrRemoved();

      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to notify sink event:',
        error
      );
    });
  });

  describe('changeAudioDeviceVolume', () => {
    it('should call pactl to set sink volume', async () => {
      await audioModule.changeAudioDeviceVolume('sink1', 42);
      expect(mockedRun).toHaveBeenCalledWith('pactl set-sink-volume sink1 42%');
      expect(mockedLogger.info).toHaveBeenCalledWith(
        'Volume set to 42% for device sink1'
      );
    });
  });

  describe('changeActiveAudioDevice', () => {
    beforeEach(() => {
      mockedRun.mockClear();
      mockedLogger.info.mockClear();
    });

    it('should call pactl to set default sink for output flow', async () => {
      await audioModule.changeActiveAudioDevice('output', 'sink2');
      expect(mockedRun).toHaveBeenCalledWith('pactl set-default-sink sink2');
      expect(mockedLogger.info).toHaveBeenCalledWith(
        'Active output device changed to sink2'
      );
    });

    it('should warn for unsupported flow types', async () => {
      await audioModule.changeActiveAudioDevice('input', 'source1');
      expect(mockedRun).not.toHaveBeenCalled();
      expect(mockedLogger.warn).toHaveBeenCalledWith(
        'Unsupported flow type: input'
      );
    });
  });

  describe('getSinks', () => {
    it('should return sinks from pactl', async () => {
      const mockSinks = [{ name: 'sink1' }];
      mockedRun.mockResolvedValue(JSON.stringify(mockSinks));
      const sinks = await audioModule.getSinks();
      expect(mockedRun).toHaveBeenCalledWith('pactl --format json list sinks');
      expect(sinks).toEqual(mockSinks);
    });

    it('should throw an error if pactl fails', async () => {
      const error = new Error('Unexpected error');
      mockedRun.mockRejectedValue(error);
      await expect(audioModule.getSinks()).rejects.toThrow(error);
      expect(mockedLogger.error).toHaveBeenCalledWith(
        'Failed to list sinks:',
        error
      );
    });
  });
});
