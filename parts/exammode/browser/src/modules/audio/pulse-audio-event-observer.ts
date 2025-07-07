import { spawn, ChildProcess } from 'node:child_process';
import { PulseAudioEvent } from '../../types/types';
import { logger } from '../../utils/logger';
import * as concatjson from 'concatjson';

export type PulseAudioEventCallback = (event: PulseAudioEvent) => Promise<void>;

/**
 * Monitors PulseAudio events via `pactl subscribe` and invokes callbacks for detected changes.
 */
export class PulseAudioEventObserver {
  private static readonly PROCESS_RESTART_DELAY = 1000;

  private readonly callback: PulseAudioEventCallback;
  private eventObserverProcess: ChildProcess | null = null;

  constructor(callback: PulseAudioEventCallback) {
    this.callback = callback;
  }

  observe(): void {
    logger.debug('Starting audio event observation');

    this.eventObserverProcess = spawn('pactl', ['--format=json', 'subscribe'], {
      detached: true,
      stdio: ['ignore', 'pipe', 'pipe'],
      env: {
        ...process.env,
        LC_ALL: 'C'
      }
    });

    if (!this.eventObserverProcess.stdout) {
      logger.error('Failed to access audio event observer process output');
      return;
    }

    // Listen for audio events
    this.eventObserverProcess.stdout
      .pipe(concatjson.parse()) // The JSON event objects might be on different lines or not
      .on('data', this.callback.bind(this));

    this.eventObserverProcess.stderr?.on('data', (data: Buffer) => {
      logger.error('Audio error event:', data.toString());
    });

    this.eventObserverProcess.on('error', error => {
      logger.error('Audio event observer process error:', error);
    });

    this.eventObserverProcess.on('exit', (code, signal) => {
      logger.warn(
        `Audio event observer process exited with code ${code} and signal ${signal}`
      );

      // Restart the process if it exits unexpectedly
      if (code !== 0 && signal !== 'SIGTERM') {
        logger.info('Restarting audio event observer process...');
        setTimeout(
          () => this.observe(),
          PulseAudioEventObserver.PROCESS_RESTART_DELAY
        );
      }
    });
  }

  stop(): void {
    if (this.eventObserverProcess) {
      logger.debug('Stopping audio event observation');
      this.eventObserverProcess.kill('SIGTERM');
      this.eventObserverProcess = null;
    }
  }
}
