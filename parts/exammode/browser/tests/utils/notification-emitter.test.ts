import { NotificationEmitter } from '../../src/utils/notification-emitter';
import { logger } from '../../src/utils/logger';

jest.mock('../../src/utils/logger');

describe('NotificationEmitter', () => {
  let emitter: NotificationEmitter;

  beforeEach(() => {
    emitter = new NotificationEmitter();
    jest.clearAllMocks();
  });

  it('should add an event listener', () => {
    const handler = jest.fn();
    emitter.addEventListener('test', handler);
    emitter.emit('test', 'data');
    expect(handler).toHaveBeenCalledWith(emitter, 'data');
  });

  it('should remove an event listener', () => {
    const handler = jest.fn();
    emitter.addEventListener('test', handler);
    emitter.removeEventListener('test', handler);
    emitter.emit('test', 'data');
    expect(handler).not.toHaveBeenCalled();
  });

  it('should emit an event to multiple listeners', () => {
    const handler1 = jest.fn();
    const handler2 = jest.fn();
    emitter.addEventListener('test', handler1);
    emitter.addEventListener('test', handler2);
    emitter.emit('test', 'data');
    expect(handler1).toHaveBeenCalledWith(emitter, 'data');
    expect(handler2).toHaveBeenCalledWith(emitter, 'data');
  });

  it('should warn when emitting an event with no listeners', () => {
    emitter.emit('test', 'data');
    expect(logger.warn).toHaveBeenCalledWith(
      'No handlers registered for event type: test'
    );
  });

  it('should handle errors in event handlers', () => {
    const errorHandler = jest.fn(() => {
      throw new Error('Test Error');
    });
    const normalHandler = jest.fn();

    emitter.addEventListener('test', errorHandler);
    emitter.addEventListener('test', normalHandler);

    emitter.emit('test', 'data');

    expect(errorHandler).toHaveBeenCalledWith(emitter, 'data');
    expect(normalHandler).toHaveBeenCalledWith(emitter, 'data');
    expect(logger.error).toHaveBeenCalledWith(
      'Error in event handler:',
      expect.any(Error)
    );
  });
});
