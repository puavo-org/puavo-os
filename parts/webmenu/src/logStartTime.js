
function logStartTime(msg) {
    if (!process.env.WM_STARTUP_TIME) return;
    var sinceStart = (Date.now()/1000) - parseInt(process.env.WM_STARTUP_TIME, 10);
    console.log(msg.trim() + "  in " + sinceStart + " seconds");
}

module.exports = logStartTime;
