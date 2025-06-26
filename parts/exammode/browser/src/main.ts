import { SurveillanceModule } from './modules/surveillance/surveillance-module';
import { EncryptionModule } from './modules/encryption/encryption-module';
import { BrightnessModule } from './modules/brightness/brightness-module';
import { ShutdownModule } from './modules/shutdown/shutdown-module';
import { SessionModule } from './modules/session/session-module';
import { AudioModule } from './modules/audio/audio-module';
import { app, BrowserWindow, ipcMain } from 'electron';
import type { Module } from './modules/module';
import type { BrowserConfig } from './types';
import { logger } from './utils/logger';
import path from 'path';

const DEFAULT_WINDOW_WIDTH = 1024;
const DEFAULT_WINDOW_HEIGHT = 768;
const DEFAULT_PAGE_URL = 'https://example.com';

const config: BrowserConfig = {
  // TODO: Redirect to a custom page
  url: app.commandLine.getSwitchValue('url') ?? DEFAULT_PAGE_URL,
  width:
    parseInt(app.commandLine.getSwitchValue('width')) || DEFAULT_WINDOW_WIDTH,
  height:
    parseInt(app.commandLine.getSwitchValue('height')) || DEFAULT_WINDOW_HEIGHT,
  kiosk: app.commandLine.hasSwitch('kiosk'),
  debug: app.commandLine.hasSwitch('dev'),
};

// Configure logger based on debug switch
logger.setDebugEnabled(config.debug);

const modules: Array<Module> = [];

function dispatchClientNotification(
  win: BrowserWindow,
  type: string,
  body: any
): void {
  logger.debug(`Relaying client notification: ${type}`);
  win.webContents.send('dispatchClientNotification', type, body);
}

function registerNotifyHandlers(module: Module): void {
  const handlerDefinitions = module.getNotifyHandlerDefinitions();

  for (const handlerDefinition of handlerDefinitions) {
    const [name, handler] = handlerDefinition;
    ipcMain.handle(name, async (_, ...args) => {
      try {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
        await handler(...args);
      } catch (error) {
        logger.error(`Error in notify handler "${name}":`, error);
      }
    });
  }
}

function registerQueryHandlers(module: Module): void {
  const handlerDefinitions = module.getQueryHandlerDefinitions();

  for (const handlerDefinition of handlerDefinitions) {
    const [name, handler] = handlerDefinition;
    ipcMain.handle(name, async (_, ...args) => {
      try {
        // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument
        return await handler(...args);
      } catch (error) {
        logger.error(`Error in query handler "${name}":`, error);
        throw error; // Re-throw to propagate the error to the renderer process
      }
    });
  }
}

function registerModules(win: BrowserWindow): void {
  if (!config.kiosk) {
    return;
  }

  logger.info('Registering modules...');

  modules.push(
    new AudioModule(),
    new BrightnessModule(),
    new EncryptionModule(),
    new SessionModule(),
    new ShutdownModule(),
    new SurveillanceModule()
  );

  for (const module of modules) {
    module.dispatchClientNotification = dispatchClientNotification.bind(
      null,
      win
    );
    registerNotifyHandlers(module);
    registerQueryHandlers(module);
  }
}

function createWindow(): BrowserWindow {
  const win = new BrowserWindow({
    width: config.width,
    height: config.height,
    frame: !config.kiosk,
    kiosk: config.kiosk,
    autoHideMenuBar: true,
    webPreferences: {
      devTools: config.debug,
      // NOTE:
      // This configuration allows websites to access Node.js APIs directly.
      // Required for the WebSocket fix to work, but reduces security isolation
      // between the web content and system resources.
      // We maintain the IPC infrastructure so that when the WebSocket issue
      // can be resolved, we can enable proper security (contextIsolation: true,
      // nodeIntegration: false) without major refactoring.
      nodeIntegration: true, // IPC access
      contextIsolation: !config.kiosk, // For WebSocket fix
      ...(config.kiosk ? { preload: path.join(__dirname, 'preload.js') } : {}),
    },
  });

  win.webContents.on(
    'console-message',
    (_event, _level, message, line, sourceId) =>
      logger.debug(
        `Console message: ${message} (source: ${sourceId}, line: ${line})`
      )
  );

  win.webContents.on(
    'did-fail-load',
    (_event, errorCode, errorDescription, validatedURL) => {
      logger.error(
        `Failed to load the page: ${validatedURL} (${errorDescription}, error code: ${errorCode})`
      );
    }
  );

  win.webContents.on('did-finish-load', () => {
    logger.info(`Page finished loading: ${config.url}`);
  });

  win.webContents.on('before-input-event', (event, input) => {
    if (input.control) {
      switch (input.key) {
        case '+':
        case '=':
          event.preventDefault();
          win.webContents.setZoomLevel(win.webContents.getZoomLevel() + 1);
          break;
        case '-':
          event.preventDefault();
          win.webContents.setZoomLevel(win.webContents.getZoomLevel() - 1);
          break;
        case '0':
          event.preventDefault();
          win.webContents.setZoomLevel(0);
          break;
        case 'ArrowLeft':
          event.preventDefault();
          if (win.webContents.canGoBack()) {
            win.webContents.goBack();
          }
          break;
        case 'ArrowRight':
          event.preventDefault();
          if (win.webContents.canGoForward()) {
            win.webContents.goForward();
          }
          break;
      }
    }
  });

  win.maximize();

  void win.loadURL(config.url);

  return win;
}

app.on(
  'certificate-error',
  (event, _webContents, url, error, _certificate, callback) => {
    logger.warn(`Certificate error bypassed: ${url} (${error})`);
    event.preventDefault();
    callback(true);
  }
);

void app.whenReady().then(createWindow).then(registerModules);
