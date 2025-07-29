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

  const controller = new ToolbarController(
    errorPageUrl,
    locale,
    themeMediaQuery,
    toolbarElement
  );
  controller.setNavigationVisibility(showNavigation);
  controller.setReloadButtonVisibility(showReload);
  controller.setAddressBarVisibility(showAddressBar);
});
