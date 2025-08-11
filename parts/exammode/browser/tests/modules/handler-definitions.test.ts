import { SurveillanceModule } from '../../src/modules/surveillance/surveillance-module';
import { BrightnessModule } from '../../src/modules/brightness/brightness-module';
import { EncryptionModule } from '../../src/modules/encryption/encryption-module';
import { ScreenshotModule } from '../../src/modules/screenshot/screenshot-module';
import { ShutdownModule } from '../../src/modules/shutdown/shutdown-module';
import { SessionModule } from '../../src/modules/session/session-module';
import { AudioModule } from '../../src/modules/audio/audio-module';
import { createMockWebContents } from '../__mocks__/electron';
import type { Module } from '../../src/modules/module';

// Mock node:fs, because brightness module IO prevents Jest from exiting
jest.mock('node:fs', () => ({
  watch: jest.fn(),
}));

jest.mock('../../src/utils/shell', () => ({
  run: jest.fn().mockResolvedValue(''),
}));

jest.mock('../../src/modules/audio/pulse-audio-event-observer', () => ({
  PulseAudioEventObserver: jest.fn().mockImplementation(() => ({
    observe: jest.fn(),
    stop: jest.fn(),
  })),
}));

describe('ModuleHandlerDefinitions', () => {
  it('all modules should have valid handler definitions', () => {
    const mockShutdownCallback = jest.fn();

    const modules: Module[] = [
      new AudioModule(),
      new BrightnessModule(),
      new EncryptionModule(),
      new ScreenshotModule(createMockWebContents() as any),
      new SessionModule(),
      new ShutdownModule(mockShutdownCallback),
      new SurveillanceModule(),
    ];

    for (const module of modules) {
      const notifyHandlers = module.getNotifyHandlerDefinitions();
      const queryHandlers = module.getQueryHandlerDefinitions();

      for (const [name, handler] of notifyHandlers.entries()) {
        expect(typeof name === 'string').toBe(true);
        expect(handler).toBeInstanceOf(Function);
      }

      for (const [name, handler] of queryHandlers.entries()) {
        expect(typeof name === 'string').toBe(true);
        expect(handler).toBeInstanceOf(Function);
      }
    }
  });
});
