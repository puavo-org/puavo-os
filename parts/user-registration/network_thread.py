# The "Create account" page

import http.client
import socket
import threading

from logger import log


class NetworkThread(threading.Thread):
    def __init__(self, request_method, event):
        super().__init__()
        self.request_method = request_method
        self.event = event
        self.response = {}


    def run(self):
        self.response['failed'] = False
        self.response['error'] = None

        response = None

        conn = None

        try:
            server_addr = open('/etc/puavo/domain', 'rb').read().decode('utf-8').strip()

            conn = http.client.HTTPSConnection(server_addr, timeout=60)

            self.request_method(conn)

            # Must read the response here, because the "finally" handler
            # closes the connection and that happens before we can read
            # the response
            response = conn.getresponse()
            self.response['code'] = response.status
            self.response['headers'] = response.getheaders()
            self.response['data'] = response.read()

        except socket.timeout:
            self.response['error'] = 'timeout'
            self.response['failed'] = True
        except http.client.HTTPException as e:
            self.response['error'] = e
            self.response['failed'] = True
        except Exception as e:
            log.error('got error when connecting to %s: %s', server_addr, e)
            self.response['error'] = e
            self.response['failed'] = True
        finally:
            if conn:
                conn.close()

        self.event.set()
