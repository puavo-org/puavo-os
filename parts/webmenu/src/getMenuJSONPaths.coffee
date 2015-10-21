
path = require "path"

getMenuJSONPaths = (webmenuHome) ->

    if process.env.WM_MENU_JSON_PATH
        dirs = process.env.WM_MENU_JSON_PATH.split(":")
    else
        dirs = [
            webmenuHome,
            "/etc/webmenu"
            path.normalize(__dirname + "/../")
        ]

    # Try generated menu.json from the --use-xdg switch
    suffixes = ["-generated"]

    # Try language specific menu files
    # https://www.gnu.org/software/gettext/manual/html_node/Locale-Environment-Variables.html
    for envar in ["LANGUAGE", "LC_ALL", "LC_MESSAGES", "LANG"]
        if process.env[envar]
            suffixes = suffixes.concat(
                process.env[envar].split(":").map (s) -> "-#{ s }"
            )

    # try plain menu file last (the one shipped with webmenu)
    suffixes.push("")

    menu_json_paths = []
    for dir in dirs
        for suffix in suffixes
            menu_json_paths.push(path.join(dir, "menu#{ suffix }.yaml"))
            menu_json_paths.push(path.join(dir, "menu#{ suffix }.json"))

    return menu_json_paths

module.exports = getMenuJSONPaths
