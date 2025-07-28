import { BrowserWindow, ipcMain } from 'electron';
import type { Module } from '../modules/module';
import { logger } from '../utils/logger';

export class ModuleManager {
  private modules: Array<Module> = [];

  constructor(private readonly win: BrowserWindow) {}

  public setModules(modules: Array<Module>): void {
    this.modules = modules;
  }

  private dispatchClientNotification(type: string, body: any): void {
    logger.debug(`Relaying client notification: ${type}`);
    this.win.webContents.send('dispatchClientNotification', type, body);
  }

  private registerNotifyHandlers(module: Module): void {
    const handlerDefinitions = module.getNotifyHandlerDefinitions();

    for (const handlerDefinition of handlerDefinitions) {
      const [name, handler] = handlerDefinition;
      ipcMain.handle(name, async (_, ...args) => {
        try {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-argument
          await handler(...args);
        } catch (error) {
          logger.error(`Error in notify handler "${name}":`, error);
        }
      });
    }
  }

  private registerQueryHandlers(module: Module): void {
    const handlerDefinitions = module.getQueryHandlerDefinitions();

    for (const handlerDefinition of handlerDefinitions) {
      const [name, handler] = handlerDefinition;
      ipcMain.handle(name, async (_, ...args) => {
        try {
          // eslint-disable-next-line @typescript-eslint/no-unsafe-return, @typescript-eslint/no-unsafe-argument
          return await handler(...args);
        } catch (error) {
          logger.error(`Error in query handler "${name}":`, error);
          throw error; // Re-throw to propagate the error to the renderer process
        }
      });
    }
  }

  public registerModules(): void {
    logger.info('Registering modules...');

    for (const module of this.modules) {
      module.dispatchClientNotification = this.dispatchClientNotification.bind(
        this
      );
      this.registerNotifyHandlers(module);
      this.registerQueryHandlers(module);
    }
  }
}
