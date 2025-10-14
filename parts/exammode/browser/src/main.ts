import { SurveillanceModule } from './modules/surveillance/surveillance-module';
import { EncryptionModule } from './modules/encryption/encryption-module';
import { BrightnessModule } from './modules/brightness/brightness-module';
import { ScreenshotModule } from './modules/screenshot/screenshot-module';
import { InputEventInterceptor } from './core/input-event-interceptor';
import { ShutdownModule } from './modules/shutdown/shutdown-module';
import { SessionModule } from './modules/session/session-module';
import { AudioModule } from './modules/audio/audio-module';
import { ModuleManager } from './core/module-manager';
import type { BrowserConfig } from './types/types';
import { app, WebContents } from 'electron';
import { Browser } from './core/browser';
import { logger } from './utils/logger';

const DEFAULT_WINDOW_WIDTH = 1024;
const DEFAULT_WINDOW_HEIGHT = 768;
const EMPTY_PAGE_URL = 'about:blank';

const determineLocale = () => process.env['LANG']?.split('_')[0] || 'en';

const config: BrowserConfig = {
  debug: app.commandLine.hasSwitch('dev'),
  forceFullscreen: app.commandLine.hasSwitch('force-fullscreen'),
  height:
    parseInt(app.commandLine.getSwitchValue('height')) || DEFAULT_WINDOW_HEIGHT,
  locale: app.commandLine.getSwitchValue('locale') || determineLocale(),
  modules: app.commandLine.hasSwitch('modules'),
  restrictKeybindings: app.commandLine.hasSwitch('restrict-keybindings'),
  shell: {
    show: !app.commandLine.hasSwitch('hide-shell'),
    toolbar: {
      showNavigation: !app.commandLine.hasSwitch('hide-navigation'),
      showReload: !app.commandLine.hasSwitch('hide-reload'),
      showAddressBar: !app.commandLine.hasSwitch('hide-address-bar'),
      showControlPanel: !app.commandLine.hasSwitch('hide-control-panel'),
      isAddressBarInitiallyEditable:
        app.commandLine.hasSwitch('set-address-bar-editable') ||
        !app.commandLine.hasSwitch('url'),
      keepAddressBarEditable: app.commandLine.hasSwitch(
        'set-address-bar-editable'
      ),
    },
  },
  url: app.commandLine.getSwitchValue('url') || EMPTY_PAGE_URL,
  width:
    parseInt(app.commandLine.getSwitchValue('width')) || DEFAULT_WINDOW_WIDTH,
};

if (app.commandLine.hasSwitch('kiosk')) {
  config.forceFullscreen = true;
  config.modules = true;
  config.shell.show = false;
  config.restrictKeybindings = true;
}

logger.setDebugEnabled(config.debug);

const ZOOM_MIN_LEVEL = -5;
const ZOOM_MAX_LEVEL = 5;

function clampZoomLevel(level: number): number {
  return Math.max(ZOOM_MIN_LEVEL, Math.min(ZOOM_MAX_LEVEL, level));
}

function zoomIn(contents: WebContents): void {
  const currentLevel = contents.getZoomLevel();
  const newLevel = clampZoomLevel(currentLevel + 1);
  contents.setZoomLevel(newLevel);
}

function zoomOut(contents: WebContents): void {
  const currentLevel = contents.getZoomLevel();
  const newLevel = clampZoomLevel(currentLevel - 1);
  contents.setZoomLevel(newLevel);
}

function resetZoom(contents: WebContents): void {
  contents.setZoomLevel(0);
}

function configureInputs(config: BrowserConfig): InputEventInterceptor {
  type Handler = ((webContents: WebContents) => void) | null;
  const keybindings = new Map<string, Handler>([
    ['Alt+ArrowLeft', null],
    ['Alt+ArrowRight', null],
    ['Ctrl+q', null],
    ['Ctrl+w', null],
    ['Ctrl++', zoomIn],
    ['Ctrl+Shift+?', zoomIn],
    ['Ctrl+-', zoomOut],
    ['Ctrl+0', resetZoom],
    ...((config.restrictKeybindings
      ? [
          ['F11', null],
          ['Ctrl+q', null],
          ['Ctrl+w', null],
        ]
      : []) as Array<[string, Handler]>),
  ]);
  return new InputEventInterceptor(keybindings);
}

void app.whenReady().then(() => {
  const browser = new Browser(config, configureInputs(config));
  const moduleManager = new ModuleManager(browser.browserWindow);

  if (config.modules) {
    moduleManager.setModules([
      new AudioModule(),
      new BrightnessModule(),
      new EncryptionModule(),
      new ScreenshotModule(browser.browserWindow.webContents),
      new SessionModule(),
      new ShutdownModule(() => browser.onShutdown()),
      new SurveillanceModule(),
    ]);

    moduleManager.registerModules();
  }
});
