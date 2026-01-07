import {
  SessionModule,
  PRIVATE_KEY_PATH,
  PUBLIC_KEY_PATH,
} from '../../src/modules/session/session-module';
import { constants, createPublicKey, publicEncrypt } from 'crypto';
import { logger } from '../../src/utils/logger';
import { existsSync, unlinkSync } from 'fs';
import { app } from 'electron';

jest.mock('electron', () => {
  const actual = jest.requireActual('electron');
  return {
    ...actual,
    app: {
      ...actual.app,
      getPath: jest.fn((name: string) => {
        if (name === 'home') return '/tmp/jest-home';
        return actual.app.getPath(name);
      }),
    },
  };
});

jest.mock('../../src/utils/logger');
jest.mock('../../src/utils/shell', () => ({
  run: jest.fn().mockResolvedValue('true'),
}));

describe('SessionModule', () => {
  let sessionModule: SessionModule;

  beforeEach(async () => {
    // Clean up any existing key files before each test
    if (existsSync(PRIVATE_KEY_PATH)) {
      unlinkSync(PRIVATE_KEY_PATH);
    }
    if (existsSync(PUBLIC_KEY_PATH)) {
      unlinkSync(PUBLIC_KEY_PATH);
    }

    // Reset singleton before each test
    SessionModule.resetInstance();

    // Create a new instance for testing
    sessionModule = new SessionModule();

    // Wait for async initialization to complete
    await new Promise(process.nextTick);

    jest.clearAllMocks();
  });

  afterEach(() => {
    // Reset singleton after tests
    SessionModule.resetInstance();
  });

  describe('initialization', () => {
    it('should generate session key pair on initialization', () => {
      expect(existsSync(PRIVATE_KEY_PATH)).toBe(true);
      expect(existsSync(PUBLIC_KEY_PATH)).toBe(true);
    });

    it('should load existing keys if available', async () => {
      // First instance generates keys
      const firstInstance = new SessionModule();
      await new Promise(process.nextTick);

      // Reset and create second instance, it should load existing keys
      SessionModule.resetInstance();
      const secondInstance = new SessionModule();
      await new Promise(process.nextTick);

      expect(logger.debug).toHaveBeenCalledWith(
        'Loading existing session key pair'
      );
    });
  });

  describe('getEncryptionKey', () => {
    it('should return public key in base64 format', async () => {
      const key = await sessionModule.getEncryptionKey();
      expect(key).toBeTruthy();
      expect(typeof key).toBe('string');
      expect(key.length).toBeGreaterThan(0);
    });
  });

  describe('setSessionData', () => {
    it('should perform round-trip encryption and decryption', async () => {
      // Get the public key
      const publicKeyBase64 = await sessionModule.getEncryptionKey();
      const publicKeyBuffer = Buffer.from(publicKeyBase64, 'base64');

      // Create a public key object
      const publicKey = createPublicKey({
        key: publicKeyBuffer,
        format: 'der',
        type: 'spki',
      });

      // Test data
      const sessionSecret = 'test-session-secret-12345';
      const token = 'test-token-67890';

      // Encrypt the session secret with the public key
      const encryptedSecret = publicEncrypt(
        {
          key: publicKey,
          padding: constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        Buffer.from(sessionSecret, 'utf8')
      );

      const encryptedSecretBase64 = encryptedSecret.toString('base64');

      // Verify not authenticated before setting data
      expect(sessionModule.isAuthenticated()).toBe(false);

      // The session data should decrypt successfully
      await sessionModule.setSessionData(encryptedSecretBase64, token);

      // Verify authenticated after setting data
      expect(sessionModule.isAuthenticated()).toBe(true);
      expect(sessionModule.getSessionSecret()).toBe(sessionSecret);
      expect(sessionModule.getToken()).toBe(token);
    });

    it('should fail to decrypt corrupted data', async () => {
      // Get the public key
      const publicKeyBase64 = await sessionModule.getEncryptionKey();
      const publicKeyBuffer = Buffer.from(publicKeyBase64, 'base64');

      // Create a public key object
      const publicKey = createPublicKey({
        key: publicKeyBuffer,
        format: 'der',
        type: 'spki',
      });

      // Test data
      const sessionSecret = 'test-session-secret-12345';
      const token = 'test-token-67890';

      // Encrypt the session secret with the public key
      const encryptedSecret = publicEncrypt(
        {
          key: publicKey,
          padding: constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        Buffer.from(sessionSecret, 'utf8')
      );

      // Corrupt the encrypted data by changing a byte
      const corruptedSecret = Buffer.from(encryptedSecret);
      corruptedSecret[10] = corruptedSecret[10] ^ 0xff; // Flip bits in one byte
      const corruptedSecretBase64 = corruptedSecret.toString('base64');

      // Attempt to set corrupted data - should throw
      await expect(
        sessionModule.setSessionData(corruptedSecretBase64, token)
      ).rejects.toThrow('Failed to set session data');

      // Verify still not authenticated
      expect(sessionModule.isAuthenticated()).toBe(false);
    });
  });

  describe('singleton pattern', () => {
    it('should return the same instance when calling getInstance', () => {
      const instance1 = SessionModule.getInstance();
      const instance2 = SessionModule.getInstance();
      expect(instance1).toBe(instance2);
    });

    it('should allow creating new instances directly', () => {
      const instance1 = new SessionModule();
      SessionModule.resetInstance();
      const instance2 = new SessionModule();
      expect(instance1).not.toBe(instance2);
    });
  });

  describe('when session module is disabled', () => {
    let disabledSessionModule: SessionModule;

    beforeEach(async () => {
      // Mock the shell command to return 'false'
      const { run } = require('../../src/utils/shell');
      run.mockResolvedValue('false');

      // Clean up existing keys
      if (existsSync(PRIVATE_KEY_PATH)) {
        unlinkSync(PRIVATE_KEY_PATH);
      }
      if (existsSync(PUBLIC_KEY_PATH)) {
        unlinkSync(PUBLIC_KEY_PATH);
      }

      // Reset and create a new instance
      SessionModule.resetInstance();
      disabledSessionModule = new SessionModule();

      // Wait for async initialization
      await new Promise(process.nextTick);
    });

    it('should not generate keys when disabled', () => {
      expect(existsSync(PRIVATE_KEY_PATH)).toBe(false);
      expect(existsSync(PUBLIC_KEY_PATH)).toBe(false);
    });

    it('should return empty string for encryption key', async () => {
      const key = await disabledSessionModule.getEncryptionKey();
      expect(key).toBe('');
    });

    it('should return empty string for session secret', () => {
      const secret = disabledSessionModule.getSessionSecret();
      expect(secret).toBe('');
    });

    it('should return empty string for token', () => {
      const token = disabledSessionModule.getToken();
      expect(token).toBe('');
    });

    it('should return false for isAuthenticated', () => {
      expect(disabledSessionModule.isAuthenticated()).toBe(false);
    });

    it('should not throw when setSessionData is called', async () => {
      await expect(
        disabledSessionModule.setSessionData('encrypted-data', 'token')
      ).resolves.not.toThrow();
    });
  });
});
