export interface ToolbarConfig {
  showAddressBar: boolean;
  showNavigation: boolean;
  showReload: boolean;
  showControlPanel: boolean;
}

export interface ShellConfig {
  show: boolean;
  toolbar: ToolbarConfig;
}

export interface BrowserConfig {
  debug: boolean;
  forceFullscreen: boolean;
  height: number;
  locale: string;
  modules: boolean;
  restrictKeybindings: boolean;
  shell: ShellConfig;
  url: string;
  width: number;
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

export interface PulseAudioSinkProperties {
  'device.product.name'?: string;
}

export interface PulseAudioChannelVolume {
  value: number;
  value_percent: string;
  db: string;
}

export interface PulseAudioSink {
  channel_map: string;
  name: string;
  description?: string;
  state: PulseAudioSinkState;
  volume: {
    [channel_name: string]: PulseAudioChannelVolume;
  };
  mute: boolean;
  properties: PulseAudioSinkProperties;
}

export type PulseAudioEventSource =
  | 'card'
  | 'client'
  | 'module'
  | 'server'
  | 'sink'
  | 'sink-input'
  | 'source'
  | 'source-output';

export type PulseAudioEventType = 'new' | 'change' | 'remove';

export interface PulseAudioEvent {
  index: number;
  event: PulseAudioEventType;
  on: PulseAudioEventSource;
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
