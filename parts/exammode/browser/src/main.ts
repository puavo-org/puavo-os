import { SurveillanceModule } from './modules/surveillance/surveillance-module';
import { EncryptionModule } from './modules/encryption/encryption-module';
import { BrightnessModule } from './modules/brightness/brightness-module';
import { ShutdownModule } from './modules/shutdown/shutdown-module';
import { SessionModule } from './modules/session/session-module';
import { AudioModule } from './modules/audio/audio-module';
import { app, BrowserWindow, ipcMain } from 'electron';
import type { Module } from './modules/module';
import { logger } from './utils/logger';
import * as path from 'path';

const DEFAULT_WINDOW_WIDTH = 1024;
const DEFAULT_WINDOW_HEIGHT = 768;
const DEFAULT_PAGE_URL = 'https://example.com';

const config = {
  // TODO: Redirect to a custom page
  url:
    (app.commandLine.getSwitchValue('url') || process.argv[2]) ??
    DEFAULT_PAGE_URL,
  width:
    parseInt(app.commandLine.getSwitchValue('width')) || DEFAULT_WINDOW_WIDTH,
  height:
    parseInt(app.commandLine.getSwitchValue('height')) || DEFAULT_WINDOW_HEIGHT,
  fullscreen: app.commandLine.hasSwitch('fullscreen'),
  debug: app.commandLine.hasSwitch('dev'),
};

// Configure logger based on debug switch
logger.setDebugEnabled(config.debug);

const modules = [
  new AudioModule(),
  new BrightnessModule(),
  new EncryptionModule(),
  new SessionModule(),
  new ShutdownModule(),
  new SurveillanceModule(),
];

function dispatchClientNotification(
  window: BrowserWindow,
  type: string,
  ...args: any[]
): void {
  logger.debug(`Dispatching client notification: ${type}`);
  // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
  window.webContents.send(type, ...args);
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

function registerModules(window: BrowserWindow): void {
  for (const module of modules) {
    module.dispatchClientNotification = dispatchClientNotification.bind(
      null,
      window
    );
    registerNotifyHandlers(module);
    registerQueryHandlers(module);
  }
}

function createWindow(): BrowserWindow {
  const window = new BrowserWindow({
    width: config.width,
    height: config.height,
    frame: true,
    autoHideMenuBar: true,
    fullscreen: config.fullscreen,
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
      contextIsolation: false, // For WebSocket fix
      preload: path.join(__dirname, 'preload.js'),
    },
  });

  window.webContents.on(
    'console-message',
    (_event, _level, message, line, sourceId) =>
      logger.debug(
        `Console message: ${message} (source: ${sourceId}, line: ${line})`
      )
  );

  window.webContents.on(
    'did-fail-load',
    (_event, errorCode, errorDescription, validatedURL) => {
      logger.error(
        `Failed to load the page: ${validatedURL} (${errorDescription}, error code: ${errorCode})`
      );
    }
  );

  window.webContents.on('did-finish-load', () => {
    logger.info(`Page finished loading: ${config.url}`);
  });

  window.webContents.on("before-input-event", (event, input) => {
    if (input.control) {
      switch (input.key) {
        case "+":
        case "=":
          event.preventDefault();
          window.webContents.setZoomLevel(window.webContents.getZoomLevel() + 1);
          break;
        case "-":
          event.preventDefault();
          window.webContents.setZoomLevel(window.webContents.getZoomLevel() - 1);
          break;
        case "0":
          event.preventDefault();
          window.webContents.setZoomLevel(0);
          break;
      }
    }
  });

  void window.loadURL(config.url);

  return window;
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
