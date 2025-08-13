import { ScreenshotModule } from '../../src/modules/screenshot/screenshot-module';
import { createMockWebContents } from '../__mocks__/electron';
import { logger } from '../../src/utils/logger';
import { clipboard } from 'electron';

jest.mock('../../src/utils/logger');

describe('ScreenshotModule', () => {
  let screenshotModule: ScreenshotModule;
  let webContents: any;

  beforeEach(() => {
    webContents = createMockWebContents();
    screenshotModule = new ScreenshotModule(webContents);
    (clipboard.writeImage as jest.Mock).mockClear();
    (logger.error as jest.Mock).mockClear();
    (webContents.capturePage as jest.Mock).mockReset();
  });

  it('captures a rect and writes to clipboard', async () => {
    const fakeImage = { isEmpty: () => false } as any;
    (webContents.capturePage as jest.Mock).mockResolvedValue(fakeImage);
    const dispatch = jest.fn();
    screenshotModule.dispatchClientNotification = dispatch;

    await screenshotModule.takeScreenshot(10, 20, 110, 70);

    expect(webContents.capturePage).toHaveBeenCalledWith({
      x: 10,
      y: 20,
      width: 100,
      height: 50,
    });
    expect(clipboard.writeImage).toHaveBeenCalledWith(fakeImage);
    expect(dispatch).toHaveBeenCalledWith('ScreenshotTaken', true);
  });

  it('normalizes reversed coordinates before capture', async () => {
    const fakeImage = { isEmpty: () => false } as any;
    (webContents.capturePage as jest.Mock).mockResolvedValue(fakeImage);

    await screenshotModule.takeScreenshot(100, 80, 10, 20);

    expect(webContents.capturePage).toHaveBeenCalledWith({
      x: 10,
      y: 20,
      width: 90,
      height: 60,
    });
  });

  it('reports failure when capturePage returns an empty image', async () => {
    const emptyImage = { isEmpty: () => true } as any;
    (webContents.capturePage as jest.Mock).mockResolvedValue(emptyImage);
    const dispatch = jest.fn();
    screenshotModule.dispatchClientNotification = dispatch;

    await screenshotModule.takeScreenshot(5, 5, 25, 25);

    expect(logger.error).toHaveBeenCalled();
    expect(clipboard.writeImage).not.toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('ScreenshotTaken', false);
  });

  it('reports failure for zero-area rectangle', async () => {
    const dispatch = jest.fn();
    screenshotModule.dispatchClientNotification = dispatch;

    await screenshotModule.takeScreenshot(0, 0, 0, 0);

    expect(webContents.capturePage).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('ScreenshotTaken', false);
  });

  it('reports failure for non-finite coordinates', async () => {
    const dispatch = jest.fn();
    screenshotModule.dispatchClientNotification = dispatch;

    await (screenshotModule.takeScreenshot as any)(NaN, 0, 10, 10);

    expect(webContents.capturePage).not.toHaveBeenCalled();
    expect(logger.error).toHaveBeenCalled();
    expect(dispatch).toHaveBeenCalledWith('ScreenshotTaken', false);
  });
});
