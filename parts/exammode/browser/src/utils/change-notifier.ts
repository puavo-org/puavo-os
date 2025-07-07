/**
 * A utility class that detects changes in values and only triggers the callback
 * when the value actually changes compared to the stored previous value.
 */
export class ChangeNotifier<K = any> {
  private storedValue: K | undefined;
  private readonly getValue: () => K | Promise<K>;
  private readonly callback: (value: K) => void | Promise<void>;
  private readonly isEqual: (a: K, b: K) => boolean;

  constructor(
    getValue: () => K | Promise<K>,
    callback: (value: K) => void | Promise<void>,
    isEqual: (a: K, b: K) => boolean = (a, b) => a === b
  ) {
    this.getValue = getValue;
    this.callback = callback;
    this.isEqual = isEqual;
  }

  /**
   * Fetches the current value and compares it with the stored value.
   * If they are different, it updates the stored value and calls the callback.
   */
  async checkAndNotify(): Promise<void> {
    const currentValue = await this.getValue();

    if (
      this.storedValue === undefined ||
      !this.isEqual(this.storedValue, currentValue)
    ) {
      this.storedValue = currentValue;
      await this.callback(currentValue);
    }
  }

  getStoredValue(): K | undefined {
    return this.storedValue;
  }

  reset(): void {
    this.storedValue = undefined;
  }

  setStoredValue(value: K): void {
    this.storedValue = value;
  }
}
