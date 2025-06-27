export interface BrowserConfig {
  url: string;
  width: number;
  height: number;
  kiosk: boolean;
  debug: boolean;
}

export type PulseAudioSinkState = 'RUNNING' | 'IDLE' | 'SUSPENDED';

export type AudioDeviceFlow = 'input' | 'output';

export interface AudioDevice {
  id: string;
  displayName: string;
  active: boolean;
  flow: AudioDeviceFlow;
  volume: number;
  mute: boolean;
}

export interface PulseAudioSink {
  name: string;
  description?: string;
  state: PulseAudioSinkState;
  volume?: Array<{ value_percent: string }>;
  mute: boolean;
}

export interface NotificationBody {
  Type: string;
  Body: string | number | any[];
}

export type KioskEventHandler = (self: any, data: string) => void;

export interface WindowsKioskAPI {
  addEventListener: (type: string, handler: KioskEventHandler) => void;
  removeEventListener: (type: string, handler: KioskEventHandler) => void;
  Notify: (body: string) => Promise<void>;
  Query: (body: string) => Promise<string>;
}

declare global {
  interface Window {
    chrome: {
      webview: {
        hostObjects: {
          windowsKioskAPI: WindowsKioskAPI;
        };
      };
    };
  }
}
