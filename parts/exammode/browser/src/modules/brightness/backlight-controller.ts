import { readdir } from 'node:fs/promises';
import * as path from 'node:path';
import { watch } from 'node:fs';

export class BacklightController {
  public readonly path: string;

  static async getAll(): Promise<BacklightController[]> {
    const backlightControllerDirectory = '/sys/class/backlight';
    const backlightControllers = await readdir(backlightControllerDirectory);

    return backlightControllers.map(
      name =>
        new BacklightController(path.join(backlightControllerDirectory, name))
    );
  }

  constructor(path: string) {
    this.path = path;
  }
}

export class BacklightControllerObserver {
  private readonly callback: (
    backlightController: BacklightController
  ) => Promise<void>;

  constructor(
    callback: (backlightController: BacklightController) => Promise<void>
  ) {
    this.callback = callback;
  }

  observe(backlightController: BacklightController): void {
    watch(
      `${backlightController.path}/brightness`,
      () => void this.callback(backlightController)
    );
  }
}
