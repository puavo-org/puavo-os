# config.json

Webmenu configuration

## Location

Webmenu will look it from following locations:

  1. the bundled config.json
  2. /etc/webmenu/config.json
  3. ~/.config/webmenu/config.json

It will read file from each locations and merges those into a single
configuration object. The options in latter ones will override options in
previous ones. So users can for example just override a `logoutCMD` in
`~/.config/webmenu/config.json` if needed.

## Attributes


### `dotDesktopSearchPaths`

Array of file system paths where to look for .desktop files

### `iconSearchPaths`

Array of file system paths where to look for icons for `osIcon` attributes in
menu.json.

### `fallbackIcon`

Icon to use if requested icon is not found from `iconSearchPaths`.

### `profileCMD`

Command to launch from the profile button.

The button is not displayed if this is null or undefined.

Can be any launchable menu.json item object.

### `passwordCMD`

Command to launch from the password button.

The button is not displayed if this is null or undefined.

Can be any launchable menu.json item object.


### `settingsCMD`

Command to launch from the settings button.

Can be any launchable menu.json item object.

### `shutdownCMD`

Command to shutdown the computer

### `restartCMD`

Command to restart the computer

### `sleepCMD`

Command to put the computer to sleep (aka suspend)

### `hibernateCMD`

Command to hibernate

### `maxFavorites`

Item count in favorites list.

### `feedCMD`

Shell executable string which print array of json objects to stdout. The
objects must contain a `message` field which is displayed on the Webmenu.

### `installerIcon`

Icon to be used for items when the alternative `installer` command is active.
Defaults to `kentoo` (Faenza).

