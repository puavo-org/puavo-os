import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import { logger } from '../../utils/logger';
import { run } from '../../utils/shell';
import type {
  ClientNotificationHandler,
  Module,
  NotifyHandler,
  QueryHandler,
} from '../module';
import {
  constants,
  createPrivateKey,
  generateKeyPairSync,
  privateDecrypt,
  type KeyObject,
} from 'crypto';
import { examBrowserDir } from '../../main';

const RSA_KEY_SIZE = 4096;
export const PRIVATE_KEY_PATH = examBrowserDir + 'session-private-key.pem';
export const PUBLIC_KEY_PATH  = examBrowserDir + 'session-public-key.der';

export class SessionModule implements Module {
  private static instance: SessionModule | null = null;

  dispatchClientNotification: ClientNotificationHandler = () => {};

  private sessionSecret: string = '';
  private token: string = '';
  private privateKey: KeyObject | null = null;
  private publicKeyBase64: string = '';
  private enabled: boolean = false;

  /**
   * Get the singleton instance of session module.
   * For production use, this ensures only one instance exists.
   */
  static getInstance(): SessionModule {
    if (!SessionModule.instance) {
      SessionModule.instance = new SessionModule();
    }
    return SessionModule.instance;
  }

  /**
   * Reset the singleton instance
   */
  static resetInstance(): void {
    SessionModule.instance = null;
  }

  constructor() {
    void this.initialize();
  }

  /**
   * Initialize the session module by checking if it's enabled and setting up keys if needed.
   */
  private async initialize(): Promise<void> {
    this.enabled = await this.checkIfEnabled();

    if (this.enabled) {
      this.initializeKeyPair();
    } else {
      logger.debug('Session module is disabled');
    }
  }

  /**
   * Check if session module is enabled via configuration.
   */
  private async checkIfEnabled(): Promise<boolean> {
    const result = await run('puavo-conf', ['puavo.exammode.browser.sessions.enabled']);
    return result === 'true';
  }

  /**
   * Initialize RSA key pair, either by loading from disk or generating new ones.
   */
  private initializeKeyPair(): void {
    try {
      // Try to load existing keys
      if (existsSync(PRIVATE_KEY_PATH) && existsSync(PUBLIC_KEY_PATH)) {
        logger.debug('Loading existing session key pair');
        this.loadKeyPair();
      } else {
        logger.debug('Generating new session key pair');
        this.generateKeyPair();
      }
    } catch (error) {
      logger.error('Failed to initialize key pair:', error);
      throw new Error('Failed to initialize session module');
    }
  }

  /**
   * Load existing RSA key pair from disk.
   */
  private loadKeyPair(): void {
    const privateKeyPem = readFileSync(PRIVATE_KEY_PATH, 'utf8');
    this.privateKey = createPrivateKey({
      key: privateKeyPem,
      format: 'pem',
    });

    const publicKeyDer = readFileSync(PUBLIC_KEY_PATH);
    this.publicKeyBase64 = publicKeyDer.toString('base64');
  }

  /**
   * Generate a new RSA key pair and save to disk.
   */
  private generateKeyPair(): void {
    const { privateKey, publicKey } = generateKeyPairSync('rsa', {
      modulusLength: RSA_KEY_SIZE,
      publicKeyEncoding: {
        type: 'spki',
        format: 'der',
      },
      privateKeyEncoding: {
        type: 'pkcs8',
        format: 'pem',
      },
    });

    mkdirSync(examBrowserDir, { recursive: true });

    // Save private key
    writeFileSync(PRIVATE_KEY_PATH, privateKey, { mode: 0o600 });
    logger.debug(`Private key saved to ${PRIVATE_KEY_PATH}`);

    // Save public key
    writeFileSync(PUBLIC_KEY_PATH, publicKey);
    logger.debug(`Public key saved to ${PUBLIC_KEY_PATH}`);

    // Load the keys into memory
    this.privateKey = createPrivateKey({
      key: privateKey,
      format: 'pem',
    });
    this.publicKeyBase64 = Buffer.from(publicKey).toString('base64');
  }

  /**
   * Get the public encryption key in base64 format.
   */
  async getEncryptionKey(): Promise<string> {
    return this.enabled ? this.publicKeyBase64 : '';
  }

  /**
   * Set session data by decrypting the encrypted session secret.
   */
  async setSessionData(
    encryptedSessionSecret: string,
    token: string
  ): Promise<void> {
    if (!this.enabled) {
      logger.debug('Session module is disabled, ignoring session data');
      return;
    }

    if (!this.privateKey) {
      throw new Error('Private key not initialized');
    }

    try {
      logger.debug('Setting session data');

      const encryptedData = Buffer.from(encryptedSessionSecret, 'base64');

      const sessionSecretBuffer = privateDecrypt(
        {
          key: this.privateKey,
          padding: constants.RSA_PKCS1_OAEP_PADDING,
          oaepHash: 'sha256',
        },
        encryptedData
      );

      this.sessionSecret = sessionSecretBuffer.toString('utf8');
      this.token = token;

      logger.debug('Session data set successfully');
    } catch (error) {
      logger.error('Failed to decrypt session secret:', error);
      throw new Error('Failed to set session data');
    }
  }

  /**
   * Get the current session secret.
   */
  getSessionSecret(): string {
    return this.enabled ? this.sessionSecret : '';
  }

  /**
   * Get the current session token.
   */
  getToken(): string {
    return this.enabled ? this.token : '';
  }

  /**
   * Check if session is authenticated.
   */
  isAuthenticated(): boolean {
    return this.enabled && this.sessionSecret !== '' && this.token !== '';
  }

  getNotifyHandlerDefinitions(): Map<string, NotifyHandler> {
    return new Map<string, NotifyHandler>([
      ['setSessionData', this.setSessionData.bind(this)],
    ]);
  }

  getQueryHandlerDefinitions(): Map<string, QueryHandler> {
    return new Map<string, QueryHandler>([
      ['getEncryptionKey', this.getEncryptionKey.bind(this)],
    ]);
  }
}
