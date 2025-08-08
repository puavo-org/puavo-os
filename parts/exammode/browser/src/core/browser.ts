import { InputEventInterceptor } from './input-event-interceptor';
import type { BrowserConfig } from '../types/types';
import type { LoadFileOptions } from 'electron';
import { logger } from '../utils/logger';
import { BrowserWindow } from 'electron';
import path from 'path';

const EMPTY_PAGE_URL = 'about:blank';

export class Browser {
  public readonly browserWindow: BrowserWindow;
  private readonly config: BrowserConfig;

  constructor(
    config: BrowserConfig,
    inputEventInterceptor?: InputEventInterceptor
  ) {
    this.config = config;
    this.browserWindow = this.createWindow();

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

    // Attach keybinding interceptor to the main window
    inputEventInterceptor?.attach(this.browserWindow.webContents);

    // Also attach the same interceptor to any webview that gets attached
    this.browserWindow.webContents.on(
      'did-attach-webview',
      (_event, webContents) => {
        inputEventInterceptor?.attach(webContents);
      }
    );

    if (this.config.forceFullscreen) {
      this.disableLeavingFullscreen();
    }

    this.browserWindow.maximize();
    this.loadInitialPage();
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
