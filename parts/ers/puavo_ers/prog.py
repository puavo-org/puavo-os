"""
Various program helpers
"""

# Standard library imports
import contextlib
import errno
import fcntl
import io
import locale
import logging
import logging.handlers
import os
import os.path
import sys

__all__ = [
    "LineBufferedLoggingStream",
    "singleton",
    "logging_singleton_app",
]


class LineBufferedLoggingStream(io.TextIOWrapper):
    def __init__(self, logger, level):
        self.__buffer = io.BytesIO()
        self.__logger = logger
        self.__level = level
        super().__init__(self.__buffer, line_buffering=True)

    def flush(self):
        with self.buffer.getbuffer() as buf:
            s = buf.tobytes().decode(locale.getencoding())
            if s:
                self.__logger.log(self.__level, s)
        self.buffer.truncate(0)


@contextlib.contextmanager
def singleton():
    this_prog_path = os.path.realpath(sys.argv[0])
    with open(this_prog_path, "rb") as this_prog:
        try:
            fcntl.flock(this_prog, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError as io_error:
            if io_error.errno != errno.EAGAIN:
                raise
            raise RuntimeError(
                f"program {this_prog_path!r} is already running)"
            ) from io_error
        yield


def logging_singleton_app(
    main_func,
    logger,
    stderr_logging_level=logging.ERROR,
    stdout_logging_level=logging.WARNING,
):
    original_stderr = sys.stderr

    if stderr_logging_level is not None:
        sys.stderr = LineBufferedLoggingStream(logger, stderr_logging_level)
    if stdout_logging_level is not None:
        sys.stdout = LineBufferedLoggingStream(logger, stdout_logging_level)

    logging_handlers = [
        logging.handlers.SysLogHandler(address="/dev/log"),
        logging.StreamHandler(original_stderr),
    ]

    logging.basicConfig(
        level=logging.INFO,
        handlers=logging_handlers,
        force=True,
    )
    try:
        logger.info("acquiring singleton program lock")
        with singleton():
            logger.info("calling main function")
            status = main_func()
        logger.log(
            logging.INFO if status == 0 else logging.ERROR,
            "returned from main function, status %d",
            status,
        )
    except Exception:
        logger.exception("failed")
        raise
    sys.exit(status)
