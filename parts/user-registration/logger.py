import logging
import logging.handlers

# Setup logging
log = logging.getLogger(__name__)
log.setLevel(logging.DEBUG)
handler = logging.handlers.SysLogHandler(address='/dev/log')
formatter = logging.Formatter('puavo-user-registration: %(message)s')
handler.setFormatter(formatter)
log.addHandler(handler)
