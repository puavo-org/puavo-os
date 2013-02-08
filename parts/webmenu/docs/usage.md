# Usage

## `$ webmenu`

Starts the Webmenu process. This should be kept running always. Use `webmenu-spawn` command to open it.


## `$ webmenu-spawn`

`--logout`

Spawn with logout view open

`--webmenu-exit [exit status]`

Shutdown the Webmenu process with optional exit status. Nonzero exit status causes Webmenu to be restarted.


Webmenu does not add a launcher automatically to panels yet. Use `.desktop` files from `extra/`
to create panel launchers.
