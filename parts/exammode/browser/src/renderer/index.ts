import { ControlPanelController } from './control-panel';
import { ToolbarController } from './renderer';
import './renderer.css';

document.addEventListener('DOMContentLoaded', () => {
  const themeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const toolbarElement = document.querySelector('.toolbar') as HTMLElement;

  if (!toolbarElement) {
    throw new Error('Failed to find the toolbar');
  }

  const baseUrl = window.location.href.split('/').slice(0, -1).join('/');
  const errorPageUrl = `${baseUrl}/error.html`;

  const config = new URLSearchParams(window.location.search);

  const locale = config.get('locale') || 'en';
  const showNavigation = config.get('showNavigation') !== 'false';
  const showReload = config.get('showReload') !== 'false';
  const showAddressBar = config.get('showAddressBar') !== 'false';
  const showControlPanel = config.get('showControlPanel') !== 'false';
  const isAddressBarInitiallyEditable = config.get('isAddressBarInitiallyEditable') !== 'false';
  const keepAddressBarEditable =
    config.get('keepAddressBarEditable') !== 'false';

  const pageView = document.getElementById('page') as Electron.WebviewTag;
  const controlPanel = document.getElementById('control-panel');
  const controlPanelOverlay = document.getElementById('control-panel-overlay');

  if (!controlPanel || !controlPanelOverlay) {
    throw new Error('Failed to find control panel elements');
  }

  const controlPanelController = new ControlPanelController(
    pageView,
    controlPanel,
    controlPanelOverlay
  );

  const controller = new ToolbarController(
    errorPageUrl,
    locale,
    themeMediaQuery,
    toolbarElement,
    pageView,
    controlPanelController
  );
  controller.setNavigationVisibility(showNavigation);
  controller.setReloadButtonVisibility(showReload);
  controller.setAddressBarVisibility(showAddressBar);
  controller.setControlPanelButtonVisibility(showControlPanel);
  controller.setAddressBarConfig(isAddressBarInitiallyEditable, keepAddressBarEditable);
});
