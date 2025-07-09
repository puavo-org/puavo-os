import { beforeEach } from '@jest/globals';

beforeEach(() => {
  // Clear all mocks before each test
  jest.clearAllMocks();
});

global.process = {
  ...process,
  exit: jest.fn() as any,
};

global.console = {
  ...console,
  log: jest.fn(),
  debug: jest.fn(),
  info: jest.fn(),
  warn: jest.fn(),
  error: jest.fn(),
};
