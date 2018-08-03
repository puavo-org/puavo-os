# Simple logging system that can be diverted to the console
# or a file on demand

from datetime import datetime


__enable_console = True
__enable_file = False
__file = None
__debug = True
__debug_ctr = 0


def enable_file(name='log.txt'):
    global __enable_file, __file
    __enable_file = True

    try:
        if __file:
            __file.close()

        __file = open(name, 'w')
    except Exception as e:
        import syslog

        syslog.syslog(syslog.LOG_CRIT,
                      'logger.enable_file(): cannot open file "{0}" for '
                      'writing, file output disabled: {1}'.
                      format(name, e))

        __file = None
        __enable_file = False


def disable_file():
    global __enable_file, __file

    if __file:
        __file.close()

    __enable_file = False
    __file = None


def enable_console():
    global __enable_console
    __enable_console = True


def disable_console():
    global __enable_console
    __enable_console = False


def enable_debug():
    global __debug
    __debug = True


def disable_debug():
    global __debug
    __debug = False


def __output(s):
    global __enable_console, __enable_file, __file

    if __enable_console:
        print(s)

    if __enable_file and __file:
        __file.write(s + '\n')
        __file.flush()


# ------------------------------------------------------------------------------


__num_warnings = 0
__num_errors = 0


def have_warnings():
    global __num_warnings
    return __num_warnings > 0


def have_errors():
    global __num_errors
    return __num_errors > 0


def num_warnings():
    global __num_warnings
    return __num_warnings


def num_errors():
    global __num_errors
    return __num_errors


def reset_counters():
    global __num_warnings, __num_errors
    __num_warnings = 0
    __num_errors = 0


def info(message):
    __output(str(message))


def warn(message):
    global __num_warnings
    __output('WARNING: ' + str(message))
    __num_warnings += 1


def error(message):
    global __num_errors
    __output('ERROR: ' + str(message))
    __num_errors += 1


def debug(message):
    global __debug, __debug_ctr

    if __debug:
        __output('DEBUG: ({0}) {1}'.format(__debug_ctr, message))
        __debug_ctr += 1


# Special method used at load-time so that we don't have to
# constantly haul the Logger object around
def print_time(title, start_ms, end_ms):
    __output('{0}: {1:.1f} milliseconds'.
             format(title, (end_ms - start_ms) * 1000.0))


# Meant specifically for neatly logging exception tracebacks
def traceback(trace_back):
    for row in trace_back.split('\n'):
        if row:
            __output('ERROR: >> ' + row)


def __print_time_with_message(msg):
    # close enough to ISO 8601
    info('{0} at {1} UTC'.
         format(str(msg), datetime.utcnow().
                strftime('%Y-%m-%d %H:%M:%S.%f')))


def start_banner():
    __print_time_with_message('Logging starts')


def end_banner():
    __print_time_with_message('Logging ends')
