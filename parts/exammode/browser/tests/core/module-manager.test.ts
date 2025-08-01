import { ModuleManager } from '../../src/core/module-manager';
import type { Module } from '../../src/modules/module';
import { BrowserWindow, ipcMain } from 'electron';

jest.mock('../../src/utils/logger', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    setDebugEnabled: jest.fn(),
  },
}));

describe('ModuleManager', () => {
  let moduleManager: ModuleManager;
  let mockBrowserWindow: jest.Mocked<BrowserWindow>;

  beforeEach(() => {
    mockBrowserWindow = new (BrowserWindow as any)();
    moduleManager = new ModuleManager(mockBrowserWindow);
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should register handlers for modules', () => {
    const mockModule: Module = {
      getNotifyHandlerDefinitions: () => new Map([['testNotify', jest.fn()]]),
      getQueryHandlerDefinitions: () => new Map([['testQuery', jest.fn()]]),
      dispatchClientNotification: jest.fn(),
    };

    moduleManager.setModules([mockModule]);
    moduleManager.registerModules();

    expect(ipcMain.handle).toHaveBeenCalledWith(
      'testNotify',
      expect.any(Function)
    );
    expect(ipcMain.handle).toHaveBeenCalledWith(
      'testQuery',
      expect.any(Function)
    );
  });
});
