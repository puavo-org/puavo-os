import { ChangeNotifier } from '../../src/utils/change-notifier';

describe('ChangeNotifier', () => {
  it('should call the callback when the value changes', async () => {
    let value = 1;
    const getValue = jest.fn().mockImplementation(async () => value);
    const callback = jest.fn();
    const notifier = new ChangeNotifier(getValue, callback);

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledWith(1);

    value = 2;
    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledWith(2);
    expect(callback).toHaveBeenCalledTimes(2);
  });

  it('should not call the callback when the value is the same', async () => {
    const getValue = jest.fn().mockResolvedValue(1);
    const callback = jest.fn();
    const notifier = new ChangeNotifier(getValue, callback);

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledTimes(1);

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledTimes(1);
  });

  it('should use the custom isEqual function', async () => {
    const getValue = jest.fn().mockResolvedValue({ a: 1 });
    const callback = jest.fn();
    const isEqual = (a: { a: number }, b: { a: number }) => a.a === b.a;
    const notifier = new ChangeNotifier(getValue, callback, isEqual);

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledTimes(1);

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledTimes(1);

    getValue.mockResolvedValue({ a: 2 });

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledWith({ a: 2 });
  });

  it('should reset the stored value', async () => {
    let value = 1;
    const getValue = jest.fn().mockImplementation(() => Promise.resolve(value));
    const callback = jest.fn();
    const notifier = new ChangeNotifier(getValue, callback);

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledWith(1);

    notifier.reset();
    value = 1; // Set value to the same to ensure it still notifies due to reset

    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledWith(1);
    expect(callback).toHaveBeenCalledTimes(2);
  });

  it('should allow setting the stored value', async () => {
    const getValue = jest.fn().mockResolvedValue(2);
    const callback = jest.fn();
    const notifier = new ChangeNotifier(getValue, callback);

    notifier.setStoredValue(1);
    await notifier.checkAndNotify();
    expect(callback).toHaveBeenCalledWith(2);
  });

  it('should throw an error if the callback throws an error', async () => {
    const getValue = jest.fn().mockResolvedValue(1);
    const callback = jest.fn(() => {
      throw new Error('Callback error');
    });
    const notifier = new ChangeNotifier(getValue, callback);

    await expect(notifier.checkAndNotify()).rejects.toThrow('Callback error');
  });

  it('should throw an error if isEqual throws an error', async () => {
    const getValue = jest.fn().mockResolvedValue(2);
    const callback = jest.fn();
    const isEqual = () => {
      throw new Error('isEqual error');
    };
    const notifier = new ChangeNotifier(getValue, callback, isEqual as any);
    notifier.setStoredValue(1);

    await expect(notifier.checkAndNotify()).rejects.toThrow('isEqual error');
  });
});
