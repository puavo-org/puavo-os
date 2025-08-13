import { SurveillanceModule } from '../../src/modules/surveillance/surveillance-module';
import { logger } from '../../src/utils/logger';

jest.mock('../../src/utils/logger');

describe('SurveillanceModule', () => {
  let surveillanceModule: SurveillanceModule;

  beforeEach(() => {
    surveillanceModule = new SurveillanceModule();
    (logger.warn as jest.Mock).mockClear();
  });

  describe('startSurveillance', () => {
    it('should log a warning', async () => {
      await surveillanceModule.startSurveillance();
      expect(logger.warn).toHaveBeenCalledWith(
        'Surveillance is not implemented'
      );
    });
  });
});
