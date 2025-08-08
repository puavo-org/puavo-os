import { InputEventInterceptor } from '../../src/core/input-event-interceptor';
import type { BrowserConfig } from '../../src/types/types';
import { Browser } from '../../src/core/browser';
import { BrowserWindow } from 'electron';

jest.mock('../../src/utils/logger', () => ({
  logger: {
    debug: jest.fn(),
    info: jest.fn(),
    warn: jest.fn(),
    error: jest.fn(),
    setDebugEnabled: jest.fn(),
  },
}));

jest.mock('../../src/core/input-event-interceptor', () => ({
  InputEventInterceptor: jest.fn().mockImplementation(() => ({
    attach: jest.fn(),
  })),
}));

describe('Browser', () => {
  let browser: Browser;

  const config: BrowserConfig = {
    url: 'http://localhost',
    width: 800,
    height: 600,
    forceFullscreen: true,
    locale: 'en',
    debug: false,
    shell: {
      show: false,
      toolbar: {
        showNavigation: true,
        showReload: true,
        showAddressBar: true,
        showControlPanel: true,
        isAddressBarInitiallyEditable: true,
        keepAddressBarEditable: true
      },
    },
    modules: false,
    restrictKeybindings: true,
  };

  const MockBrowserWindow = BrowserWindow as unknown as jest.Mock;

  beforeEach(() => {
    MockBrowserWindow.mockClear();
    browser = new Browser(config, new InputEventInterceptor(new Map()));
  });

  afterEach(() => {
    jest.clearAllMocks();
  });

  it('should create a BrowserWindow on instantiation', () => {
    expect(BrowserWindow).toHaveBeenCalledWith(
      expect.objectContaining({
        width: config.width,
        height: config.height,
        fullscreen: config.forceFullscreen,
        kiosk: !config.shell.show,
      })
    );
    expect(browser.browserWindow).toBe(MockBrowserWindow.mock.results[0].value);
  });

  it('should load url in kiosk mode', () => {
    const kioskConfig: BrowserConfig = {
      ...config,
      shell: { ...config.shell, show: false },
    };
    new Browser(kioskConfig, new InputEventInterceptor(new Map()));
    expect(browser.browserWindow.webContents.loadURL).toHaveBeenCalledWith(
      kioskConfig.url
    );
  });

  it('should load file in non-kiosk mode', () => {
    const nonKioskConfig: BrowserConfig = {
      ...config,
      shell: { ...config.shell, show: true },
    };
    const browser = new Browser(
      nonKioskConfig,
      new InputEventInterceptor(new Map())
    );
    expect(browser.browserWindow.webContents.loadFile).toHaveBeenCalled();
  });

  it('should prevent default on disabled keybindings', () => {
    const mockInterceptor = new InputEventInterceptor(new Map());
    new Browser(config, mockInterceptor);
    expect(mockInterceptor.attach).toHaveBeenCalled();
  });

  it('should re-enter fullscreen when left', () => {
    const fullscreenConfig: BrowserConfig = {
      ...config,
      forceFullscreen: true,
    };
    const browser = new Browser(
      fullscreenConfig,
      new InputEventInterceptor(new Map())
    );

    browser.browserWindow.emit('leave-full-screen');

    expect(browser.browserWindow.setFullScreen).toHaveBeenCalledWith(true);
  });

  it('should load blank page on shutdown', () => {
    browser.onShutdown();
    expect(browser.browserWindow.webContents.loadURL).toHaveBeenCalledWith(
      'about:blank'
    );
  });

  it('should handle page load failure by loading error page', () => {
    const failedUrl = 'http://failed.url';

    browser.browserWindow.webContents.emit(
      'did-fail-load',
      {}, // event
      -6, // errorCode: NET_ERROR
      'ERR_NAME_NOT_RESOLVED', // errorDescription
      failedUrl, // validatedURL
      true // isMainFrame
    );

    expect(browser.browserWindow.webContents.loadFile).toHaveBeenCalledWith(
      expect.stringContaining('error.html'),
      expect.objectContaining({
        query: {
          locale: config.locale,
          url: failedUrl,
        },
      })
    );
  });

  it('should not handle page load failure for non-main frames', () => {
    const failedUrl = 'http://failed.url';

    browser.browserWindow.webContents.emit(
      'did-fail-load',
      {}, // event
      -6, // errorCode: NET_ERROR
      'ERR_NAME_NOT_RESOLVED', // errorDescription
      failedUrl, // validatedURL
      false // isMainFrame: false
    );

    expect(browser.browserWindow.webContents.loadFile).not.toHaveBeenCalled();
  });
});
