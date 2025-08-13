import { ShutdownModule } from '../../src/modules/shutdown/shutdown-module';
import { logger } from '../../src/utils/logger';
import { systemBus } from 'dbus-next';

jest.mock('dbus-next', () => ({
  systemBus: jest.fn(),
}));

const mockedSystemBus = systemBus as jest.Mock;

describe('ShutdownModule', () => {
  let shutdownCallback: jest.Mock;
  let shutdownModule: ShutdownModule;
  let mockBus: any;
  let mockProxyObject: any;
  let mockExamInterface: any;

  beforeEach(() => {
    shutdownCallback = jest.fn();
    shutdownModule = new ShutdownModule(shutdownCallback);

    mockExamInterface = { QuitSession: jest.fn() };
    mockProxyObject = {
      getInterface: jest.fn().mockReturnValue(mockExamInterface),
    };
    mockBus = { getProxyObject: jest.fn().mockResolvedValue(mockProxyObject) };

    jest.spyOn(logger, 'error').mockImplementation(() => {});
    mockedSystemBus.mockImplementation(() => mockBus);

    // Clear process.exit mock (set up globally in setup.ts)
    (process.exit as unknown as jest.Mock).mockClear();
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  it('calls the shutdown callback and DBus method, then exits', async () => {
    await shutdownModule.shutdown();
    expect(shutdownCallback).toHaveBeenCalled();
    expect(mockBus.getProxyObject).toHaveBeenCalledWith(
      'org.puavo.Exam',
      '/exammode'
    );
    expect(mockProxyObject.getInterface).toHaveBeenCalledWith(
      'org.puavo.Exam.exammode'
    );
    expect(mockExamInterface.QuitSession).toHaveBeenCalled();
    expect(process.exit).toHaveBeenCalledWith(0);
  });

  it('calling shutdown callback throws an error, DBus method still called and exits', async () => {
    shutdownCallback.mockImplementation(() => {
      throw new Error('Unexpected error');
    });
    await shutdownModule.shutdown();
    expect(logger.error).toHaveBeenCalledWith(
      'Error occurred during shutdown callback:',
      expect.any(Error)
    );
    expect(mockExamInterface.QuitSession).toHaveBeenCalled();
    expect(process.exit).toHaveBeenCalledWith(0);
  });

  it('DBus fails, shutdown callback called and exits', async () => {
    mockBus.getProxyObject.mockRejectedValue(
      new Error('Unexpected DBus error')
    );
    await shutdownModule.shutdown();
    expect(shutdownCallback).toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalledWith(
      'Failed to quit session via DBus:',
      expect.any(Error)
    );
    expect(process.exit).toHaveBeenCalledWith(0);
  });
});
