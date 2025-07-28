import type { WebContents } from 'electron';
import { logger } from '../utils/logger';

type KeybindingAction = (webContents: WebContents) => void;

function generateKeyString(input: Electron.Input): string {
  const parts: string[] = [];

  if (input.control) parts.push('Ctrl');
  if (input.alt) parts.push('Alt');
  if (input.shift) parts.push('Shift');
  if (input.meta) parts.push('Meta');

  if (input.key) {
    parts.push(input.key);
  }

  return parts.join('+');
}

export class InputEventInterceptor {
  private readonly keybindings: Map<string, KeybindingAction | null>;

  constructor(keybindings: Map<string, KeybindingAction | null>) {
    this.keybindings = keybindings;
  }

  public attach(webContents: WebContents): void {
    webContents.on('before-input-event', (event, input) => {
      const keyString = generateKeyString(input);

      if (this.keybindings.has(keyString)) {
        logger.debug(`Intercepted keybinding: ${keyString}`);
        event.preventDefault();

        const action = this.keybindings.get(keyString);
        if (action) {
          action(webContents);
        }
      }
    });
  }
}
