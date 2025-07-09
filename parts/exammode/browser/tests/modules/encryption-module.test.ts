import { EncryptionModule } from '../../src/modules/encryption/encryption-module';

describe('EncryptionModule', () => {
  let encryptionModule: EncryptionModule;

  beforeEach(() => {
    encryptionModule = new EncryptionModule();
  });

  it('should return empty encryption key', async () => {
    const key = await encryptionModule.getEncryptionKey();
    expect(key).toBe('');
  });
});
