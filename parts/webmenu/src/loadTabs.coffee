

path = require "path"
{loadFallback, load, readDirectoryD} = require "./load"

getWeight = (tab) ->
    if not tab.weight
        return 10
    else
        parseFloat(tab.weight, 10)

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


  loadTabs = (webmenuHome) ->
    # The default menu.json is a single tab
    defaultTab = loadFallback(getMenuJSONPaths(webmenuHome))
    tabs = [defaultTab]

    readDirectoryD(
        "/etc/webmenu/tab.d",
        webmenuHome + "/tab.d"
    ).forEach (tabFile) ->
        try
            tabs.push(load(tabFile))
        catch err
            console.error("Invalid tab file: #{ tabFile }")

    tabs.sort (a, b) -> getWeight(a) - getWeight(b)
    return tabs.filter(Boolean)


module.exports = loadTabs



