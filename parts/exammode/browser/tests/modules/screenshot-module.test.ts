import { ScreenshotModule } from '../../src/modules/screenshot/screenshot-module';
import { logger } from '../../src/utils/logger';
import { run } from '../../src/utils/shell';

jest.mock('../../src/utils/shell');
jest.mock('../../src/utils/logger');

describe('ScreenshotModule', () => {
  let screenshotModule: ScreenshotModule;

  beforeEach(() => {
    screenshotModule = new ScreenshotModule();
    (run as jest.Mock).mockClear();
    (logger.error as jest.Mock).mockClear();
  });

  it('should call screenshot command', async () => {
    await screenshotModule.takeScreenshot();
    expect(run).toHaveBeenCalledWith(ScreenshotModule.SCREENSHOT_COMMAND);
  });

  it('should log error if screenshot command fails', async () => {
    const error = new Error('Screenshot failed');
    (run as jest.Mock).mockRejectedValue(error);
    await screenshotModule.takeScreenshot();
    expect(logger.error).toHaveBeenCalledWith(
      `Failed to take screenshot: ${error}`
    );
  });
});
