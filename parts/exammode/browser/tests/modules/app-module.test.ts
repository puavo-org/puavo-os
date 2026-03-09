import { AppModule } from '../../src/modules/app/app-module';

jest.mock('../../src/utils/logger', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
  },
}));

describe('AppModule', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('getAppInfo should return app information and log the request', async () => {
    const appModule = new AppModule();

    const info = await appModule.getAppInfo();

    expect(info).toEqual({
      appPlatform: 'Linux',
      appVersion: '2.0.0',
    });
  });

  it('getQueryHandlerDefinitions should include getAppInfo handler that works', async () => {
    const appModule = new AppModule();

    const handlers = appModule.getQueryHandlerDefinitions();
    expect(handlers).toBeInstanceOf(Map);
    expect(handlers.has('getAppInfo')).toBe(true);

    const handler = handlers.get('getAppInfo') as
      | (() => Promise<any>)
      | undefined;
    expect(typeof handler).toBe('function');

    const result = await handler!();
    expect(result).toEqual({
      appPlatform: 'Linux',
      appVersion: '2.0.0',
    });
  });

  it('getNotifyHandlerDefinitions should return an empty map', () => {
    const appModule = new AppModule();

    const notifyHandlers = appModule.getNotifyHandlerDefinitions();
    expect(notifyHandlers).toBeInstanceOf(Map);
    expect(notifyHandlers.size).toBe(0);
  });

  it('dispatchClientNotification does nothing', () => {
    const appModule = new AppModule();

    // Should be callable and not throw
    const result = appModule.dispatchClientNotification('SomeEvent', {
      foo: 'bar',
    });
    expect(result).toBeUndefined();
  });
});
