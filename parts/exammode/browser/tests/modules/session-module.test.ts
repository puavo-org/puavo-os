import { SessionModule } from '../../src/modules/session/session-module';
import { logger } from '../../src/utils/logger';

jest.mock('../../src/utils/logger');

describe('SessionModule', () => {
  let sessionModule: SessionModule;

  beforeEach(() => {
    sessionModule = new SessionModule();
    (logger.warn as jest.Mock).mockClear();
  });

  describe('setSessionSecret', () => {
    it('should log a warning', async () => {
      await sessionModule.setSessionSecret();
      expect(logger.warn).toHaveBeenCalledWith(
        'Session secret is not implemented'
      );
    });
  });
});
