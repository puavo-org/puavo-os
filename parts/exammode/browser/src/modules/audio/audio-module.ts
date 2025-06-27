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
} from '../../types/types';
import { logger } from '../../utils/logger';
import { run } from '../../utils/shell';

export class AudioModule implements Module {
  dispatchClientNotification: ClientNotificationHandler = () => {};

  async getSinks(): Promise<PulseAudioSink[]> {
    try {
      const output = await run('pactl --format json list sinks');
      return JSON.parse(output) as PulseAudioSink[];
    } catch (error) {
      logger.error('Failed to list sinks:', error);
      throw error;
    }
  }

  getSinkVolume(sink: PulseAudioSink): number {
    // Select the volume from the first channel
    const channel = sink.volume?.[0];
    if (!channel) {
      const MAX_VOLUME = 100;
      return MAX_VOLUME;
    }

    const volume_percent_string = channel.value_percent;
    return parseFloat(volume_percent_string);
  }

  async getDefaultSinkName(): Promise<string> {
    try {
      const output = await run('pactl get-default-sink');
      return output.trim();
    } catch (error) {
      logger.error('Failed to fetch the default sink:', error);
      throw error;
    }
  }

  createOutputDeviceFromSink(
    sink: PulseAudioSink,
    defaultSinkName: string
  ): AudioDevice {
    return {
      id: sink.name,
      displayName: sink.description ?? sink.name,
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

    logger.debug('Audio devices:', audioDevices);
    return audioDevices;
  }

  async changeAudioDeviceVolume(
    deviceId: string,
    volume: number
  ): Promise<void> {
    const command = `pactl set-sink-volume ${deviceId} ${volume}%`;
    await run(command);
    logger.info(`Volume set to ${volume}% for device ${deviceId}`);
  }

  async changeActiveOutputDevice(deviceId: string): Promise<void> {
    const command = `pactl set-default-sink ${deviceId}`;
    await run(command);
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

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['changeAudioDeviceVolume', this.changeAudioDeviceVolume.bind(this)],
      ['changeActiveAudioDevice', this.changeActiveAudioDevice.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getAudioDevices', this.getAudioDevices.bind(this)],
      ['getSinks', this.getSinks.bind(this)],
    ]);
  }
}
