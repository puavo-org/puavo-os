interface MockWebContents {
  send: jest.Mock;
  loadURL: jest.Mock;
  loadFile: jest.Mock;
  on: jest.Mock;
  once: jest.Mock;
  removeAllListeners: jest.Mock;
  emit: jest.Mock;
  capturePage: jest.Mock;
}

interface MockBrowserWindow {
  webContents: MockWebContents;
  on: jest.Mock;
  once: jest.Mock;
  setFullScreen: jest.Mock;
  maximize: jest.Mock;
  show: jest.Mock;
  hide: jest.Mock;
  close: jest.Mock;
  destroy: jest.Mock;
  removeAllListeners: jest.Mock;
  emit: jest.Mock;
}

export const ipcMain = {
  handle: jest.fn(),
  on: jest.fn(),
  emit: jest.fn(),
  removeAllListeners: jest.fn(),
};

function createMockEventTarget() {
  const eventListeners = new Map<string, Function[]>();

  const on = jest
    .fn()
    .mockImplementation((event: string, listener: Function) => {
      if (!eventListeners.has(event)) {
        eventListeners.set(event, []);
      }
      eventListeners.get(event)!.push(listener);
    });

  const emit = jest.fn().mockImplementation((event: string, ...args: any[]) => {
    const listeners = eventListeners.get(event) || [];
    listeners.forEach(listener => listener(...args));
  });

  return { on, emit };
}

export function createMockWebContents(): MockWebContents {
  const eventTarget = createMockEventTarget();
  return {
    send: jest.fn(),
    loadURL: jest.fn().mockResolvedValue(undefined),
    loadFile: jest.fn().mockResolvedValue(undefined),
    on: eventTarget.on,
    once: jest.fn(),
    removeAllListeners: jest.fn(),
    emit: eventTarget.emit,
    capturePage: jest.fn(),
  };
}

export const BrowserWindow = jest
  .fn()
  .mockImplementation((): MockBrowserWindow => {
    const windowEventTarget = createMockEventTarget();

    return {
      webContents: createMockWebContents(),
      on: windowEventTarget.on,
      once: jest.fn(),
      setFullScreen: jest.fn(),
      maximize: jest.fn(),
      show: jest.fn(),
      hide: jest.fn(),
      close: jest.fn(),
      destroy: jest.fn(),
      removeAllListeners: jest.fn(),
      emit: windowEventTarget.emit,
    };
  });

export const app = {
  commandLine: {
    getSwitchValue: jest.fn().mockReturnValue(''),
    hasSwitch: jest.fn().mockReturnValue(false),
  },
  whenReady: jest.fn().mockResolvedValue(undefined),
  on: jest.fn(),
  quit: jest.fn(),
  getPath: jest.fn().mockReturnValue('/mock/path'),
  getAppPath: jest.fn().mockReturnValue('/mock/app/path'),
};

export const dialog = {
  showOpenDialog: jest.fn(),
  showSaveDialog: jest.fn(),
  showMessageBox: jest.fn(),
  showErrorBox: jest.fn(),
};

export const shell = {
  openExternal: jest.fn(),
  openPath: jest.fn(),
  showItemInFolder: jest.fn(),
};

export const clipboard = {
  writeImage: jest.fn(),
};

// Create instances for testing
export const createMockBrowserWindow = (): MockBrowserWindow =>
  new BrowserWindow() as MockBrowserWindow;
