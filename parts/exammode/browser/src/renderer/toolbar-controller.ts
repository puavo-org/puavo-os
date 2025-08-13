/* eslint-disable no-console */
import { ControlPanelController } from './control-panel';

export class ToolbarController {
  private backButton!: HTMLButtonElement;
  private errorPageUrl: string;
  private forwardButton!: HTMLButtonElement;
  private locale: string;
  private reloadButton!: HTMLButtonElement;
  private controlPanelButton!: HTMLButtonElement;
  private addressBar!: HTMLInputElement;
  private pageView!: Electron.WebviewTag;
  private readonly themeMediaQuery: MediaQueryList;
  private controlPanelController: ControlPanelController;
  private keepAddressBarEditable: boolean = false;

  constructor(
    errorPageUrl: string,
    locale: string,
    themeMediaQuery: MediaQueryList,
    toolbarElement: HTMLElement,
    pageView: Electron.WebviewTag,
    controlPanelController: ControlPanelController
  ) {
    this.errorPageUrl = errorPageUrl;
    this.locale = locale;
    this.pageView = pageView;
    this.themeMediaQuery = themeMediaQuery;
    this.controlPanelController = controlPanelController;
    this.initializeElements(toolbarElement);
    this.loadConfiguredURL();
    this.attachEventListeners();
    this.setupThemeDetection();
  }

  private initializeElements(toolbarElement: HTMLElement): void {
    this.backButton = toolbarElement.querySelector(
      '#back-button'
    ) as HTMLButtonElement;
    this.forwardButton = toolbarElement.querySelector(
      '#forward-button'
    ) as HTMLButtonElement;
    this.reloadButton = toolbarElement.querySelector(
      '#reload-button'
    ) as HTMLButtonElement;
    this.controlPanelButton = toolbarElement.querySelector(
      '#control-panel-button'
    ) as HTMLButtonElement;
    this.addressBar = toolbarElement.querySelector(
      '#address-bar'
    ) as HTMLInputElement;
    this.pageView = document.getElementById('page') as Electron.WebviewTag;
  }

  private loadConfiguredURL(): void {
    // We have to wait for the webview to be attached before we can load the URL
    this.pageView.addEventListener('did-attach', () => {
      try {
        // The main process passes the initial URL via query parameters
        const url =
          new URLSearchParams(window.location.search).get('url') ?? '';
        void this.pageView.loadURL(url);
      } catch (error) {
        console.error('Failed to get configured URL:', error);
        // Fallback to default URL from HTML
        this.updateAddressBar(this.pageView.src);
      }
    });
  }

  private attachEventListeners(): void {
    this.backButton.addEventListener('click', this.goBack.bind(this));
    this.forwardButton.addEventListener('click', this.goForward.bind(this));
    this.reloadButton.addEventListener('click', this.reload.bind(this));
    this.controlPanelButton.addEventListener(
      'click',
      this.openControlPanel.bind(this)
    );

    this.addressBar.addEventListener(
      'keypress',
      this.handleAddressBarKeypress.bind(this)
    );

    this.pageView.addEventListener(
      'dom-ready',
      this.handleDocumentReady.bind(this)
    );
    this.pageView.addEventListener(
      'did-start-loading',
      this.handleStartLoading.bind(this)
    );
    this.pageView.addEventListener(
      'did-stop-loading',
      this.handleStopLoading.bind(this)
    );
    this.pageView.addEventListener(
      'did-navigate',
      this.handleNavigate.bind(this)
    );
    this.pageView.addEventListener(
      'did-navigate-in-page',
      this.handleNavigateInPage.bind(this)
    );
    this.pageView.addEventListener(
      'did-fail-load',
      this.handleFailLoad.bind(this)
    );
    this.pageView.addEventListener(
      'did-stop-loading',
      this.handleLoaded.bind(this)
    );

    window.addEventListener('focus', this.handleWindowFocus.bind(this));
  }

  private setupThemeDetection(): void {
    // Configure the initial theme based on the user preferences
    this.applyTheme(this.themeMediaQuery.matches);

    // Listen for theme changes
    this.themeMediaQuery.addEventListener('change', event => {
      this.applyTheme(event.matches);
    });
  }

  private applyTheme(isDark: boolean): void {
    const theme = isDark ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', theme);
  }

  private handleAddressBarKeypress(event: KeyboardEvent): void {
    if (event.key !== 'Enter') {
      return;
    }

    const url = this.addressBar.value.trim();

    if (url) {
      const normalizedUrl = this.normalizeUrl(url);
      this.pageView.src = normalizedUrl;
      this.addressBar.blur();
      this.updateAddressBar(normalizedUrl);
      this.setLoading(true);
    }
  }

  private handleDocumentReady(): void {
    this.setLoading(false);
    this.updateButtonStates();
  }

  private handleStartLoading(): void {
    this.setLoading(true);
  }

  private handleStopLoading(): void {
    this.setLoading(false);
    this.updateButtonStates();
  }

  private handleNavigate(event: Electron.DidNavigateEvent): void {
    this.updateAddressBar(event.url);
    this.updateButtonStates();
  }

  private handleNavigateInPage(event: Electron.DidNavigateInPageEvent): void {
    this.updateAddressBar(event.url);
    this.updateButtonStates();
  }

  private handleWindowFocus(): void {
    this.updateButtonStates();
  }

  private normalizeUrl(url: string): string {
    // Handle special URLs
    if (url === 'about:blank' || url.startsWith('file://')) {
      return url;
    }

    // Add the protocol if it is missing
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return `https://${url}`;
    }

    return url;
  }

  private updateButtonStates(): void {
    this.backButton.disabled = !this.pageView.canGoBack();
    this.forwardButton.disabled = !this.pageView.canGoForward();
  }

  private setLoading(isLoading: boolean): void {
    this.reloadButton.classList.toggle('loading', isLoading);
    this.reloadButton.disabled = isLoading;
    document.body.classList.toggle('loading', isLoading);
  }

  private isContentPage(url: string): boolean {
    return url.startsWith('http://') || url.startsWith('https://');
  }

  private updateAddressBar(url: string): void {
    if (this.isContentPage(url)) {
      this.addressBar.value = url;
    } else {
      // Display the address bar as "blank" for special sites (e.g. blank and error page)
      this.addressBar.value = '';
    }
  }

  private showErrorPage(failedUrl: string): void {
    if (!this.pageView) {
      console.error('Failed to show error page due to missing webview');
      return;
    }

    const errorPageUrl = this.buildErrorPageUrl(failedUrl);

    if (!errorPageUrl) {
      console.error('Failed to build error page URL');
      return;
    }

    // Load error page in the webview
    void this.pageView.loadURL(errorPageUrl);
    this.updateAddressBar(failedUrl);
    this.setLoading(false);
  }

  private buildErrorPageUrl(failedUrl: string): string | null {
    const urlParameters = new URLSearchParams({
      url: failedUrl,
      locale: this.locale,
    });
    return `${this.errorPageUrl}?${urlParameters.toString()}`;
  }

  private handleLoaded(_event: DOMEvent): void {
    const hasLockedAddressBar = this.addressBar.disabled;

    if (hasLockedAddressBar) {
      return;
    }

    // Lock the address bar after successful content page load, unless configured otherwise
    if (this.isContentPage(this.pageView.src) && !this.keepAddressBarEditable) {
      this.addressBar.disabled = true;
      // Clear the history, so the user can't go back
      this.pageView.clearHistory();
    }
  }

  private handleFailLoad(event: Electron.DidFailLoadEvent): void {
    // Show the error page only if the actual page fails to load.
    // Without this, other frames (e.g. iframes) could trigger the error page.
    if (!event.isMainFrame) {
      return;
    }

    // Don't show the error page for cancelled loads or if error code is acceptable (ERR_ABORTED or OK)
    if (event.errorCode === -3 || event.errorCode === 0) {
      return;
    }

    console.error(
      `Failed to load page: ${event.validatedURL}, error: ${event.errorCode}`
    );
    this.showErrorPage(event.validatedURL);
  }

  goBack(): void {
    if (this.pageView.canGoBack()) {
      this.pageView.goBack();
    }
    this.updateButtonStates();
  }

  goForward(): void {
    if (this.pageView.canGoForward()) {
      this.pageView.goForward();
    }
    this.updateButtonStates();
  }

  reload(): void {
    this.pageView.reload();
    this.setLoading(true);
  }

  setNavigationVisibility(show: boolean): void {
    if (this.backButton) {
      this.backButton.style.display = show ? 'flex' : 'none';
    }
    if (this.forwardButton) {
      this.forwardButton.style.display = show ? 'flex' : 'none';
    }
  }

  setReloadButtonVisibility(show: boolean): void {
    if (this.reloadButton) {
      this.reloadButton.style.display = show ? 'block' : 'none';
    }
  }

  setAddressBarVisibility(show: boolean): void {
    if (this.addressBar) {
      this.addressBar.style.display = show ? 'flex' : 'none';
    }
  }

  openControlPanel(): void {
    this.controlPanelController.toggle();
  }

  setControlPanelButtonVisibility(show: boolean): void {
    if (this.controlPanelButton) {
      this.controlPanelButton.style.display = show ? 'flex' : 'none';
    }
  }

  setAddressBarConfig(
    isAddressBarInitiallyEditable: boolean,
    keepAddressBarEditable: boolean
  ) {
    this.addressBar.disabled = !isAddressBarInitiallyEditable;
    this.keepAddressBarEditable = keepAddressBarEditable;
  }
}
