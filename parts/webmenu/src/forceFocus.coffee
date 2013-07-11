{exec} = require "child_process"

###*
# Use wmctrl cli tool force focus on Webmenu. Calls the wmctrl after a given
# timeout to give it some time to appear on window lists. It will also retry
# itself if it fails which might happen on slow or high loaded machines.
#
# @param {Number} nextTry timeout to wait before calling wmctrl
# @param {Number} retries* one or more timeouts to retry
###
forceFocus = (title, nextTry, retries...) ->
    if not nextTry
        console.error "wmctrl retries exhausted. Failed to activate Webmenu!"
        return

    setTimeout ->
        cmd = "wmctrl -F -R #{ title }"
        wmctrl = exec cmd, (err, stdout, stderr) ->
            if err
                console.warn "wmctrl: failed: '#{ cmd }'. Error: #{ JSON.stringify err }"
                console.warn "wmctrl: stdout: #{ stdout } stderr: #{ stderr }"
                console.warn "wmctrl: Retrying after #{ nextTry }ms"
                forceFocus(title, retries...)
    , nextTry

module.exports = forceFocus
