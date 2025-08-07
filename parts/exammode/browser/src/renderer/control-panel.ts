export class ControlPanelController {
  private controlPanel!: HTMLElement;
  private controlPanelOverlay!: HTMLElement;
  private controlPanelClose!: HTMLButtonElement;
  private zoomSlider!: HTMLInputElement;
  private zoomLevelElement!: HTMLElement;
  private isVisible: boolean = false;
  private pageView: Electron.WebviewTag;

  constructor(
    pageView: Electron.WebviewTag,
    controlPanel: HTMLElement,
    controlPanelOverlay: HTMLElement
  ) {
    this.pageView = pageView;
    this.controlPanel = controlPanel;
    this.controlPanelOverlay = controlPanelOverlay;
    this.initializeElements();
    this.attachEventListeners();
  }

  private initializeElements(): void {
    this.controlPanelClose = this.controlPanel.querySelector(
      '#control-panel-close'
    ) as HTMLButtonElement;
    this.zoomSlider = this.controlPanel.querySelector(
      '#zoom-slider'
    ) as HTMLInputElement;
    this.zoomLevelElement = this.controlPanel.querySelector(
      '#zoom-level'
    ) as HTMLElement;

    if (!this.controlPanel) {
      throw new Error('Control panel element not found');
    }
    if (!this.controlPanelOverlay) {
      throw new Error('Control panel overlay element not found');
    }
    if (!this.controlPanelClose) {
      throw new Error('Control panel close button not found');
    }
  }

  private attachEventListeners(): void {
    this.controlPanelClose.addEventListener('click', this.hide.bind(this));

    // Close the control panel when the user clicks outside the panel
    this.controlPanelOverlay.addEventListener('click', this.hide.bind(this));

    // Support closing by pressing the escape key
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape' && this.isVisible) {
        this.hide();
      }
    });

    // Prevent panel clicks from closing the panel
    this.controlPanel.addEventListener('click', event => {
      event.stopPropagation();
    });

    this.zoomSlider.addEventListener('input', this.handleZoomSlider.bind(this));
  }

  private handleZoomSlider(): void {
    const zoomLevel = parseFloat(this.zoomSlider.value);
    this.pageView.setZoomLevel(zoomLevel);
    this.updateZoomLevel();
  }

  private updateZoomLevel(): void {
    if (!this.zoomLevelElement || !this.zoomSlider) {
      return;
    }

    const zoomLevel = parseFloat(this.zoomSlider.value);
    this.zoomLevelElement.textContent = `${Math.round(zoomLevel * 100)}%`;
  }

  private updateSliderPosition(): void {
    if (!this.zoomSlider) {
      return;
    }

    const currentZoom = this.pageView.getZoomLevel();
    this.zoomSlider.value = currentZoom.toString();
    this.updateZoomLevel();
  }

  show(): void {
    if (this.isVisible) {
      return;
    }

    this.isVisible = true;
    this.controlPanel.classList.add('visible');
    this.controlPanelOverlay.classList.add('visible');

    this.updateZoomLevel();
    this.updateSliderPosition();
  }

  hide(): void {
    if (!this.isVisible) {
      return;
    }

    this.isVisible = false;
    this.controlPanel.classList.remove('visible');
    this.controlPanelOverlay.classList.remove('visible');
  }

  toggle(): void {
    if (this.isVisible) {
      this.hide();
    } else {
      this.show();
    }
  }
}
