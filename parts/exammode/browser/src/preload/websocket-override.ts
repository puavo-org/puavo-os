import { logger } from '../utils/logger';

export function setupWebSocketOverride(): void {
  logger.debug('Registering WebSocket override for', location.host);
  const OriginalWebSocket = window.WebSocket;

  // eslint-disable-next-line @typescript-eslint/no-unsafe-assignment
  window.WebSocket = function (
    url: string | URL,
    protocols?: string | string[]
  ) {
    logger.debug('Creating a WebSocket:', url, location.host);
    if (url === '/ktp/ws/status') {
      const newProtocol = location.protocol === 'https:' ? 'wss' : 'ws';
      const newUrl = `${newProtocol}://${location.host}/ktp/ws/status`;
      logger.debug(`Redirecting the WebSocket: ${url} → ${newUrl}`);
      return new OriginalWebSocket(newUrl, protocols);
    }
    return new OriginalWebSocket(url, protocols);
  } as any;
}
