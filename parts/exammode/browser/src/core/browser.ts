import { SessionModule } from '../modules/session/session-module';
import { InputEventInterceptor } from './input-event-interceptor';
import type { LoadFileOptions, WebContents } from 'electron';
import type { BrowserConfig } from '../types/types';
import { logger } from '../utils/logger';
import { BrowserWindow } from 'electron';
import { createHmac } from 'crypto';
import path from 'path';

const EMPTY_PAGE_URL = 'about:blank';

export class Browser {
  public readonly browserWindow: BrowserWindow;
  private readonly config: BrowserConfig;

  constructor(config: BrowserConfig) {
    this.config = config;
    this.browserWindow = this.createWindow();

    // Setup HTTP request header modification
    this.setupRequestHeaders(this.browserWindow.webContents);

    // Remove Electron from the user agent because
    // it improves the behavior of some exam software
    const userAgent = this.browserWindow.webContents
      .getUserAgent()
      .replace(/\sElectron\/\S+/g, '');
    this.browserWindow.webContents.setUserAgent(userAgent);

    this.browserWindow.webContents.on(
      'did-fail-load',
      (_event, _errorCode, _errorDescription, validatedURL, isMainFrame) => {
        // Show the error page only if the actual page fails to load.
        // Without this, other frames (e.g. iframes) could trigger the error page.
        if (isMainFrame) {
          this.handlePageLoadFailure(validatedURL);
        }
      }
    );

    if (this.config.forceFullscreen) {
      this.disableLeavingFullscreen();
    }

    this.browserWindow.maximize();
    this.loadInitialPage();
  }

  public attachInputEventInterceptor(
    inputEventInterceptor: InputEventInterceptor
  ): void {
    // Attach keybinding interceptor to the main window
    inputEventInterceptor.attach(this.browserWindow.webContents);

    // Also attach the same interceptor to any webview that gets attached
    this.browserWindow.webContents.on(
      'did-attach-webview',
      (_event, webContents) => {
        inputEventInterceptor.attach(webContents);
        this.setupRequestHeaders(webContents);
      }
    );
  }

  /**
   * Add authentication headers to HTTP requests if session is authenticated.
   */
  private addAuthenticationHeaders(
    details: Electron.OnBeforeSendHeadersListenerDetails,
    callback: (response: Electron.BeforeSendResponse) => void
  ): void {
    const sessionModule = SessionModule.getInstance();

    if (sessionModule.isAuthenticated()) {
      const now = Math.floor(Date.now() / 1000);
      const timestampHeader = now.toString();
      const requestUrl = details.url;
      const message = `${timestampHeader}:${requestUrl}`;

      const authHeader = createHmac('sha256', sessionModule.getSessionSecret())
        .update(message)
        .digest('base64');

      details.requestHeaders['X-App-Auth'] = authHeader;
      details.requestHeaders['X-App-Timestamp'] = timestampHeader;
      details.requestHeaders['X-Original-URL'] = requestUrl;
    }

    callback({ requestHeaders: details.requestHeaders });
  }

  /**
   * Setup request header modification for the specified WebContents.
   */
  private setupRequestHeaders(webContents: WebContents): void {
    const session = webContents.session;

    session.webRequest.onBeforeSendHeaders((details, callback) => {
      this.addAuthenticationHeaders(details, callback);
    });
  }

  private disableLeavingFullscreen(): void {
    // Even if we leave the fullscreen another way, we return to fullscreen immediately
    this.browserWindow.on('leave-full-screen', () => {
      this.browserWindow.setFullScreen(true);
    });
  }

  private handlePageLoadFailure(url: string): void {
    logger.error(`Failed to load the page: ${url}`);
    void this.loadErrorPage(url);
  }

  private async loadErrorPage(failedUrl: string): Promise<void> {
    const errorPagePath = path.resolve(__dirname, 'renderer', 'error.html');
    const loadOptions: LoadFileOptions = {
      query: {
        locale: this.config.locale,
        url: failedUrl,
      },
    };

    await this.browserWindow.webContents.loadFile(errorPagePath, loadOptions);
  }

  private loadInitialPage(): void {
    if (!this.config.shell.show) {
      void this.browserWindow.webContents.loadURL(this.config.url);
    } else {
      logger.info(`Loading renderer with URL: ${this.config.url}`);

      const loadPath = path.resolve(__dirname, 'renderer', 'index.html');
      const loadOptions: LoadFileOptions = {
        query: {
          locale: this.config.locale,
          url: this.config.url,
          showNavigation: this.config.shell.toolbar.showNavigation.toString(),
          showReload: this.config.shell.toolbar.showReload.toString(),
          showAddressBar: this.config.shell.toolbar.showAddressBar.toString(),
          showControlPanel:
            this.config.shell.toolbar.showControlPanel.toString(),
          isAddressBarInitiallyEditable:
            this.config.shell.toolbar.isAddressBarInitiallyEditable.toString(),
          keepAddressBarEditable:
            this.config.shell.toolbar.keepAddressBarEditable.toString(),
        },
      };

      void this.browserWindow.webContents.loadFile(loadPath, loadOptions);
    }
  }

  private createWindow(): BrowserWindow {
    return new BrowserWindow({
      width: this.config.width,
      height: this.config.height,
      frame: this.config.shell.show,
      fullscreen: this.config.forceFullscreen,
      kiosk: !this.config.shell.show,
      autoHideMenuBar: true,
      title: ' ', // Hide the title
      webPreferences: {
        devTools: this.config.debug,
        // NOTE:
        // This configuration allows websites to access Node.js APIs directly.
        // Required for the WebSocket fix to work, but reduces security isolation
        // between the web content and system resources.
        // We maintain the IPC infrastructure so that when the WebSocket issue
        // can be resolved, we can enable proper security (contextIsolation: true,
        // nodeIntegration: false) without major refactoring.
        nodeIntegration: true, // IPC access
        contextIsolation: !this.config.modules, // For WebSocket fix
        webviewTag: !this.config.modules,
        ...(this.config.modules
          ? { preload: path.join(__dirname, 'preload.js') }
          : {}),
      },
    });
  }

  public onShutdown(): void {
    void this.browserWindow.webContents.loadURL(EMPTY_PAGE_URL);
  }
}
