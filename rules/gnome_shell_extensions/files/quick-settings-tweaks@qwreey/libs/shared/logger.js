// Prefixed, leveled logger
function Logger(str) {
    if (str instanceof Function)
        str = str();
    if (Logger.show_info)
        console.log(Logger.LOG_INFO_HEADER + str);
}
(function (Logger) {
    Logger.LOG_HEADER_PREFIX = "";
    Logger.LOG_INFO_HEADER = "";
    Logger.LOG_DEBUG_HEADER = "";
    Logger.LOG_ERROR_HEADER = "";
    Logger.show_info = true;
    function setHeader(header) {
        Logger.LOG_HEADER_PREFIX = header;
        Logger.LOG_INFO_HEADER = `${header} (info) `;
        Logger.LOG_DEBUG_HEADER = `${header} (debug) `;
        Logger.LOG_ERROR_HEADER = `${header} (error) `;
    }
    Logger.setHeader = setHeader;
    let LogLevel;
    (function (LogLevel) {
        LogLevel[LogLevel["none"] = -1] = "none";
        LogLevel[LogLevel["error"] = 0] = "error";
        LogLevel[LogLevel["info"] = 1] = "info";
        LogLevel[LogLevel["debug"] = 2] = "debug";
    })(LogLevel = Logger.LogLevel || (Logger.LogLevel = {}));
    const void_function = (() => { });
    function debug_internal(str) {
        if (str instanceof Function)
            str = str();
        console.log(Logger.LOG_DEBUG_HEADER + str);
    }
    function error_internal(str) {
        if (str instanceof Function)
            str = str();
        console.log(`${Logger.LOG_ERROR_HEADER}${str}\n${new Error().stack}`);
    }
    function setLogLevel(level) {
        Logger.debug = level >= LogLevel.debug
            ? debug_internal
            : void_function;
        Logger.error = level >= LogLevel.error
            ? error_internal
            : void_function;
        Logger.show_info = level >= LogLevel.info;
        Logger.currentLevel = level;
    }
    Logger.setLogLevel = setLogLevel;
})(Logger || (Logger = {}));
export default Logger;
