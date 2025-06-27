import { ToolbarController } from './renderer';
import './renderer.css';

document.addEventListener('DOMContentLoaded', () => {
  const themeMediaQuery = window.matchMedia('(prefers-color-scheme: dark)');
  const toolbarElement = document.querySelector('.toolbar') as HTMLElement;

  if (!toolbarElement) {
    throw new Error('Failed to find the toolbar');
  }

  new ToolbarController(themeMediaQuery, toolbarElement);
});
