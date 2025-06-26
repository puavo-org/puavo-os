import { setupWebSocketOverride } from './utils/websocket-override';
import { KioskAPI } from './api/kiosk-api';
import { logger } from './utils/logger';
import { ipcRenderer } from 'electron';

setupWebSocketOverride();

logger.info('Registering the Kiosk API...');

window.chrome ??= {} as any;
window.chrome.webview ??= {} as any;
window.chrome.webview.hostObjects ??= {} as any;

const api = new KioskAPI();
window.chrome.webview.hostObjects.windowsKioskAPI = api;

logger.info('Kiosk API registered!');

ipcRenderer.on(
  'dispatchClientNotification',
  (_event, type: string, body: any) => {
    logger.debug('Dispatching client notification:', type);
    // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
    api.emit('ClientNotification', JSON.stringify({ Type: type, Body: body }));
  }
);
