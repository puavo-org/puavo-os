import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import type {
  AudioDevice,
  PulseAudioSink,
  AudioDeviceFlow,
  PulseAudioEvent,
} from '../../types/types';
import { PulseAudioEventObserver } from './pulse-audio-event-observer';
import { ChangeNotifier } from '../../utils/change-notifier';
import { logger } from '../../utils/logger';
import { run } from '../../utils/shell';

export class AudioModule implements Module {
  static readonly FALLBACK_DISPLAY_NAME = 'Audio device';
  static readonly VOLUME_STEP = 5;

  readonly audioEventObserver: PulseAudioEventObserver;
  readonly audioDevicesChangeNotifier: ChangeNotifier<AudioDevice[]>;
  readonly activeDeviceChangeNotifier: ChangeNotifier<string>;

  dispatchClientNotification: ClientNotificationHandler = () => {};

  constructor() {
    this.audioEventObserver = new PulseAudioEventObserver(
      this.onAudioEvent.bind(this)
    );

    // Use change notifiers to only dispatch notifications when
    // actual changes occur. Change notifiers should also prevent
    // any infinite notification loops from occurring.
    this.audioDevicesChangeNotifier = new ChangeNotifier(
      () => this.getAudioDevices(),
      this.notifyAudioDevicesChanged.bind(this),
      (a, b) => JSON.stringify(a) === JSON.stringify(b) // Deep comparison for audio devices
    );

    this.activeDeviceChangeNotifier = new ChangeNotifier(
      () =>
        this.getDefaultSinkName().catch(error => {
          logger.error('Failed to get default sink name:', error);
          return '';
        }),
      this.notifyActiveDeviceChanged.bind(this)
    );

    void this.unloadStreamRestoreModule();
    void this.registerAudioEventObserver();
  }

  private isValidIdentifier(
    identifier: string | undefined
  ): identifier is string {
    const invalidIdentifiers = ['(null)', ''];

    return (
      identifier !== undefined &&
      !invalidIdentifiers.includes(identifier.trim())
    );
  }

  private notifyAudioDevicesChanged(audioDevices: AudioDevice[]): void {
    this.dispatchClientNotification('AudioDevicesChanged', audioDevices);
  }

  async notifyActiveDeviceChanged(activeDeviceId: string): Promise<void> {
    if (!activeDeviceId) {
      logger.error('Received empty active device ID');
      return;
    }

    const audioDevices = await this.getAudioDevices();
    const activeDevice = audioDevices.find(
      device => device.id === activeDeviceId
    );

    if (activeDevice) {
      this.dispatchClientNotification('ActiveAudioDeviceChanged', [
        activeDevice.flow,
        activeDevice.id,
      ]);
    }
  }

  async onSinkAddedOrRemoved(): Promise<void> {
    try {
      await this.audioDevicesChangeNotifier.checkAndNotify();
      await this.activeDeviceChangeNotifier.checkAndNotify();
    } catch (exception) {
      logger.error('Failed to notify sink event:', exception);
    }
  }

  async onAudioEvent(audioEvent: PulseAudioEvent): Promise<void> {
    try {
      const { event, on } = audioEvent;

      if ((event === 'new' || event === 'remove') && on === 'sink') {
        await this.onSinkAddedOrRemoved();
      }
    } catch (exception) {
      logger.error('Failed to process audio event:', exception);
    }
  }

  registerAudioEventObserver(): void {
    logger.debug('Registering audio event observer');

    try {
      this.audioEventObserver.observe();
    } catch (exception) {
      logger.error('Failed to register audio event observer:', exception);
    }
  }

  async unloadStreamRestoreModule(): Promise<void> {
    // Module description:
    // Automatically restore the volume/mute/device state of streams
    // (configuration is saved in a GDBM database).
    // This module prevents proper audio routing when the default sink changes.
    // Without unloading it, existing audio streams (like website audio) remain
    // bound to the previous sink instead of switching to the new default sink.
    try {
      await run('pactl', ['unload-module', 'module-stream-restore']);
    } catch (exception) {
      logger.error(
        "Failed to unload 'module-stream-restore' from PulseAudio:",
        exception
      );
    }

    logger.info("Unloaded 'module-stream-restore' from PulseAudio");
  }

  async getSinks(): Promise<PulseAudioSink[]> {
    try {
      const output = await run('pactl', ['--format', 'json', 'list', 'sinks']);
      const all_sinks = JSON.parse(output) as PulseAudioSink[];
      return all_sinks.filter(
        sink => 'flags' in sink
                  && Array.isArray(sink['flags'])
                  && sink['flags'].includes('HW_VOLUME_CTRL'));
    } catch (error) {
      logger.error('Failed to list sinks:', error);
      throw error;
    }
  }

  getSinkVolume(sink: PulseAudioSink): number {
    const MAX_VOLUME = 100;

    // Select the volume from the first channel.
    // Channels can have different volume levels,
    // but 'pactl' sets the same volume for all
    // channels in our case.
    const channelNames = sink.channel_map.split(',');

    if (channelNames.length === 1 && !channelNames[0]?.trim()) {
      logger.error('No channels found for sink:', sink.name);
      return MAX_VOLUME;
    }

    const channelName = channelNames[0];

    if (!this.isValidIdentifier(channelName)) {
      logger.error(
        `Invalid channel name '${channelName}' for sink '${sink.name}'`
      );
      return MAX_VOLUME;
    }

    const channel = sink.volume[channelName];

    if (!channel?.value_percent) {
      logger.error('Failed to get volume for sink:', sink.name);
      return MAX_VOLUME;
    }

    const volumePercentString = channel.value_percent;
    return parseFloat(volumePercentString);
  }

  async getDefaultSinkName(): Promise<string> {
    try {
      const output = await run('pactl', ['get-default-sink']);
      return output.trim();
    } catch (error) {
      logger.error('Failed to fetch the default sink:', error);
      throw error;
    }
  }

  private getDisplayNameForSink(sink: PulseAudioSink): string {
    const displayNames = [
      sink.description,
      sink.properties['device.product.name'],
      sink.name,
    ];

    return (
      displayNames.find(this.isValidIdentifier.bind(this)) ??
      AudioModule.FALLBACK_DISPLAY_NAME
    );
  }

  createOutputDeviceFromSink(
    sink: PulseAudioSink,
    defaultSinkName: string
  ): AudioDevice {
    return {
      id: sink.name,
      displayName: this.getDisplayNameForSink(sink),
      active: sink.name === defaultSinkName,
      flow: 'output',
      volume: this.getSinkVolume(sink),
      mute: sink.mute || false,
    };
  }

  async getAudioDevices(): Promise<AudioDevice[]> {
    const sinks = await this.getSinks();
    const defaultSinkName = await this.getDefaultSinkName();
    logger.debug('Default sink name:', defaultSinkName);
    const audioDevices: AudioDevice[] = [];

    for (const sink of sinks) {
      audioDevices.push(this.createOutputDeviceFromSink(sink, defaultSinkName));
    }

    return audioDevices.sort((device1, device2) =>
      device1.displayName.localeCompare(device2.displayName)
    );
  }

  async changeAudioDeviceVolume(
    deviceId: string,
    volume: number
  ): Promise<void> {
    if (typeof deviceId !== 'string') {
      throw new Error(`Invalid device ID: ${deviceId}`);
    }

    if (typeof volume !== 'number' || !(volume >= 0 && volume <= 100)) {
      throw new Error(`Volume must be between 0 and 100`);
    }

    await run('pactl', ['set-sink-volume', deviceId, `${volume}%`]);
    logger.info(`Volume set to ${volume}% for device ${deviceId}`);
    if (volume > 0) {
      await run('pactl', ['set-sink-mute', deviceId, '0']);
      logger.info(`Set mute off for device ${deviceId}`);
    } else {
      await run('pactl', ['set-sink-mute', deviceId, '1']);
      logger.info(`Set mute on for device ${deviceId}`);
    }
  }

  async changeActiveOutputDevice(deviceId: string): Promise<void> {
    if (typeof deviceId !== 'string') {
      throw new Error(`Invalid device ID: ${deviceId}`);
    }

    await run('pactl', ['set-default-sink', deviceId]);
    logger.info(`Active output device changed to ${deviceId}`);
  }

  async changeActiveAudioDevice(
    flow: AudioDeviceFlow,
    deviceId: string
  ): Promise<void> {
    if (flow === 'output') {
      await this.changeActiveOutputDevice(deviceId);
    } else {
      // TODO: Support input devices
      logger.warn(`Unsupported flow type: ${flow}`);
    }
  }

  async adjustVolumeUp(): Promise<void> {
    const devices = await this.getAudioDevices();
    const activeDevice = devices.find(
      device => device.active && device.flow === 'output'
    );

    if (!activeDevice) {
      logger.warn('No active output device found for volume adjustment');
      return;
    }

    const newVolume = Math.min(
      100,
      activeDevice.volume + AudioModule.VOLUME_STEP
    );
    await this.changeAudioDeviceVolume(activeDevice.id, newVolume);

    const isMuted = newVolume === 0;
    this.dispatchClientNotification('AudioDeviceVolumeChanged', [
      activeDevice.id,
      newVolume,
      isMuted,
    ]);
  }

  async adjustVolumeDown(): Promise<void> {
    const devices = await this.getAudioDevices();
    const activeDevice = devices.find(
      device => device.active && device.flow === 'output'
    );

    if (!activeDevice) {
      logger.warn('No active output device found for volume adjustment');
      return;
    }

    const newVolume = Math.max(
      0,
      activeDevice.volume - AudioModule.VOLUME_STEP
    );
    await this.changeAudioDeviceVolume(activeDevice.id, newVolume);

    const isMuted = newVolume === 0;
    this.dispatchClientNotification('AudioDeviceVolumeChanged', [
      activeDevice.id,
      newVolume,
      isMuted,
    ]);
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['changeAudioDeviceVolume', this.changeAudioDeviceVolume.bind(this)],
      ['changeActiveAudioDevice', this.changeActiveAudioDevice.bind(this)],
      ['adjustVolumeUp', this.adjustVolumeUp.bind(this)],
      ['adjustVolumeDown', this.adjustVolumeDown.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getAudioDevices', this.getAudioDevices.bind(this)],
      ['getSinks', this.getSinks.bind(this)],
    ]);
  }
}
