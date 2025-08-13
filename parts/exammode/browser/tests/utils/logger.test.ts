import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import { logger } from '../../src/utils/logger';

describe('Logger', () => {
  const consoleLogSpy = jest.spyOn(console, 'log');

  beforeEach(() => {
    // Reset any mock state and clear spies
    jest.clearAllMocks();
    // Reset logger to default state before each test
    logger.setDebugEnabled(false);
  });

  describe('logging methods without debug mode', () => {
    it('should log info messages', () => {
      logger.info('Test info');
      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('[INFO]'),
        'Test info',
      );
    });

    it('should log warn messages', () => {
      logger.warn('Test warn');
      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('[WARN]'),
        'Test warn',
      );
    });

    it('should log error messages', () => {
      logger.error('Test error');
      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('[ERROR]'),
        'Test error',
      );
    });

    it('should not log debug messages by default', () => {
      logger.debug('Test debug');
      expect(consoleLogSpy).not.toHaveBeenCalled();
    });

    it('should handle objects as arguments', () => {
      const testObject = { key: 'value' };
      logger.info('Test with object:', testObject);
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('[INFO]'),
        'Test with object:',
        testObject,
      );
    });
  });

  describe('setDebugEnabled', () => {
    it('should enable debug logging when set to true', () => {
      logger.setDebugEnabled(true);
      logger.debug('Test debug');
      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
      expect(consoleLogSpy).toHaveBeenCalledWith(
        expect.stringContaining('[DEBUG]'),
        'Test debug',
      );
    });

    it('should disable debug logging when set to false', () => {
      logger.setDebugEnabled(true);
      logger.debug('Debug message when enabled');
      expect(consoleLogSpy).toHaveBeenCalledTimes(1);

      // Then disable it
      logger.setDebugEnabled(false);
      logger.debug('Debug message when disabled');
      // The call count should still be 1 from the previous call
      expect(consoleLogSpy).toHaveBeenCalledTimes(1);
    });
  });
});
