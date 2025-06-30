/* eslint-disable no-console */
export class ToolbarController {
  private backButton!: HTMLButtonElement;
  private forwardButton!: HTMLButtonElement;
  private reloadButton!: HTMLButtonElement;
  private addressBar!: HTMLInputElement;
  private pageView!: Electron.WebviewTag;
  private readonly themeMediaQuery: MediaQueryList;

  constructor(themeMediaQuery: MediaQueryList, toolbarElement: HTMLElement) {
    this.themeMediaQuery = themeMediaQuery;
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
    // Handle special case for about:blank
    if (url === 'about:blank') {
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

  private updateAddressBar(url: string): void {
    if (url !== 'about:blank') {
      this.addressBar.value = url;
    } else {
      // Display the address bar as "blank"
      this.addressBar.value = '';
    }
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

  zoomIn(): void {
    this.pageView.setZoomLevel(this.pageView.getZoomLevel() + 1);
  }

  zoomOut(): void {
    this.pageView.setZoomLevel(this.pageView.getZoomLevel() - 1);
  }

  resetZoom(): void {
    this.pageView.setZoomLevel(1);
  }

  getZoomLevel(): number {
    return this.pageView.getZoomLevel();
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

  setAddressBarVisiblity(show: boolean): void {
    if (this.addressBar) {
      this.addressBar.style.display = show ? 'flex' : 'none';
    }
  }
}
