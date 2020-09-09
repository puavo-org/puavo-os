# Downloads the user avatar from the API server, caches it and
# updates the avatar icon

import logging
import threading
import time         # oh, I wish
import os.path


class AvatarDownloaderThread(threading.Thread):
    # How long to wait until we start downloading the avatar image?
    INITIAL_WAIT = 30

    # How long to wait between avatar download retries?
    RETRY_WAIT = 60

    # How many times we'll keep trying until giving up?
    MAX_ATTEMPTS = 10


    def __init__(self, destination, avatar_object):
        super().__init__()
        self.__destination = destination        # where to cache the file
        self.__avatar_object = avatar_object    # the avatar button object


    def run(self):
        time.sleep(self.INITIAL_WAIT)

        logging.info('The avatar update thread is starting')

        import subprocess
        import getpass

        for attempt in range(0, self.MAX_ATTEMPTS):
            try:
                uri = '/v3/users/' + getpass.getuser() + '/profile.jpg'

                logging.info('Downloading user avatar from "%s", attempt %d/%d...',
                             uri, attempt + 1, self.MAX_ATTEMPTS)

                start_time = time.perf_counter()

                proc = subprocess.Popen(['puavo-rest-request', uri, '--user-krb'],
                                        stdout=subprocess.PIPE,
                                        stderr=subprocess.PIPE)

                proc.wait()

                if proc.returncode != 0:
                    raise RuntimeError("'puavo-rest-request' failed with code {0}".
                                       format(proc.returncode))

                # Got it! We didn't specify -o, so the image data waits for
                # us in stdout.
                image = proc.stdout.read()

                end_time = time.perf_counter()

                logging.info('Downloaded %d bytes of avatar image data in %s ms',
                             len(image), '{0:.1f}'.format((end_time - start_time) * 1000.0))

                # Wrap this in its own exception handler, so if it fails,
                # we just return instead of redownloading the image
                try:
                    name = os.path.join(self.__destination, 'avatar.jpg')
                    logging.info('Saving the avatar image to "%s"', name)

                    open(name, 'wb').write(image)
                    self.__avatar_object.load_avatar(name)
                except Exception as exception:
                    # Why must everything fail?
                    logging.warning('Failed to save the downloaded avatar '
                                    'image: %s', str(exception))
                    logging.warning('New avatar image not set')

                logging.info('The avatar update thread is exiting')
                return
            except Exception as exception:
                logging.error('Could not download the user avatar: %s',
                              str(exception))

            # Retry, if possible
            if attempt < self.MAX_ATTEMPTS - 1:
                logging.info('Retrying avatar download in %d seconds...',
                             self.RETRY_WAIT)
                time.sleep(self.RETRY_WAIT)

        logging.error('Giving up on trying to download the user avatar, '
                      'tried %d times', self.MAX_ATTEMPTS)
        logging.info('The avatar update thread is exiting')
