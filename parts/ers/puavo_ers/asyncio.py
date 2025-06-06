"""
Asyncio utils
"""

# Standard library imports
import aionotify
import asyncio
import logging
import os.path
import signal

__all__ = [
    "FileMonitor",
    "new_event_loop",
]


class FileMonitor:
    def __init__(self, loop, path, cb):
        if not os.path.exists(path):
            raise FileNotFoundError(path)
        self.__loop = loop
        self.__watcher = aionotify.Watcher()
        self.__watcher.watch(
            path,
            aionotify.Flags.MODIFY | aionotify.Flags.CREATE | aionotify.Flags.DELETE,
        )
        self.__task = None
        self.__cb = cb

    async def __run(self):
        await self.__watcher.setup(self.__loop)
        while True:
            event = await self.__watcher.get_event()
            await self.__cb(event)

    def start(self):
        self.__task = self.__loop.create_task(self.__run())

    def stop(self):
        self.__watcher.close()
        if self.__task is not None:
            self.__task.cancel()


def new_event_loop(
    stop_signals=(signal.SIGTERM, signal.SIGINT, signal.SIGQUIT, signal.SIGTSTP),
    logger=None,
):
    if logger is None:
        logger = logging.getLogger()

    loop = asyncio.new_event_loop()

    async def _stop_loop():
        loop.stop()

    def _stop(sig):
        for stop_signal in stop_signals:
            signal.signal(stop_signal, signal.SIG_IGN)
        logger.info("stopping due to caught signal %r", sig)
        for task in asyncio.all_tasks():
            task.cancel()
        asyncio.ensure_future(_stop_loop())

    for sig in stop_signals:
        loop.add_signal_handler(sig, _stop, sig)

    return loop
