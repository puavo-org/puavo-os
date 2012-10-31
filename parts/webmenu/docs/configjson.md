
# config.json

Webmenu configuration.

Webmenu will look it from following locations:

  1. ~/.config/webmenu/config.json
  2. /etc/webmenu/config.json
  3. the bundled config.json

## Attributes


### `dotDesktopSearchPaths`

Array of file system paths where to look for .desktop files

### `iconSearchPaths`

Array of file system paths where to look for icons for `osIcon` attributes for
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

### `maxFavorites`

Item count in favorites list.

