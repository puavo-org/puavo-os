import { WindowsKioskAPI } from '../types/types';
import { getTranslations } from './translations';
import './error.css';

interface ErrorPageControllerOptions {
  container?: HTMLElement;
  api?: WindowsKioskAPI;
}

class ErrorPageController {
  private retryButton: HTMLButtonElement;
  private exitButton: HTMLButtonElement;
  private titleElement: HTMLElement;
  private messageElement: HTMLElement;
  private failedUrl: string = '';
  private api?: WindowsKioskAPI;

  constructor(options: ErrorPageControllerOptions) {
    const container = options.container || document;

    this.retryButton = container.querySelector(
      '#retry-button'
    ) as HTMLButtonElement;
    this.exitButton = container.querySelector(
      '#exit-button'
    ) as HTMLButtonElement;
    this.titleElement = container.querySelector('.error-title') as HTMLElement;
    this.messageElement = container.querySelector(
      '.error-message'
    ) as HTMLElement;

    if (options.api) {
      this.api = options.api;
    }

    this.initialize();
  }

  private initialize(): void {
    this.setupTheme();
    this.parseUrlParameters();
    this.setupTranslations();
    this.setupEventListeners();
    this.updateUI();
  }

  private setupTheme(): void {
    const themeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
    this.applyTheme(themeMediaQuery.matches);

    themeMediaQuery.addEventListener('change', event => {
      this.applyTheme(event.matches);
    });
  }

  private applyTheme(isDark: boolean): void {
    const theme = isDark ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', theme);
  }

  private parseUrlParameters(): void {
    const urlParameters = new URLSearchParams(window.location.search);
    this.failedUrl = urlParameters.get('url') || '';
  }

  private setupTranslations(): void {
    const translations = getTranslations();
    this.titleElement.textContent = translations.error['error.title'];
    this.messageElement.textContent = translations.error['error.message'];
    this.retryButton.textContent = translations.error['error.retry'];
    this.exitButton.textContent = translations.error['error.exit'];
  }

  private setupEventListeners(): void {
    this.retryButton.addEventListener('click', () => {
      this.handleRetry();
    });

    this.exitButton.addEventListener('click', () => {
      this.handleExit();
    });
  }

  private updateUI(): void {
    // Display the exit button only if the modules have been loaded
    if (this.api) {
      this.exitButton.style.display = 'inline-block';
    }
  }

  private handleRetry(): void {
    if (!this.failedUrl) {
      return;
    }

    this.retryButton.disabled = true;

    const translations = getTranslations();
    this.retryButton.textContent = translations.error['error.loading'];

    window.location.href = this.failedUrl;
  }

  private handleExit(): void {
    this.exitButton.disabled = true;

    const translations = getTranslations();
    this.exitButton.textContent = translations.error['error.exiting'];

    this.api?.Notify?.(
      JSON.stringify({
        Type: 'ShutdownRequested',
        Body: {},
      })
    );
  }
}

document.addEventListener('DOMContentLoaded', () => {
  new ErrorPageController({
    api: window.chrome?.webview?.hostObjects?.windowsKioskAPI,
  });
});
