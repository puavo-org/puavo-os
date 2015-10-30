# menu files

Menu content is created from JSON and YAML files. The files are read from
following locations:

  1. `~/.config/webmenu/menu.{json,yaml}`
  2. `/etc/webmenu/menu.{json,yaml}`
  3. the bundled `menu.json`

The first one found will be used as the menu content.

Webmenu can also have tabs. The tabs can be defined in following locations:

  1. `~/.config/webmenu/tab.d/*.{json,yaml}`
    - Ex. `~/.config/webmenu/tab.d/mytab.yaml`
  2. `/etc/webmenu/tab.d/*.{json,yaml}`


Each file will represent a single tab. The data structure is exactly the same
in every file.

## Structure

Menu file is a nested object presentation of menus and launchable items.

Every object must have a `type` attribute which can be one of following:

### `menu`

Menu object contains all the menu items. This is the root object, but it can
also contain other menu objects.

Attributes

  - `name`: {String, required} Name of the item
  - `items`: {Array, required} Array of launcher object and/or menu objects
  - `weight`: {Number} Set tab order. Tabs are sorted as ascending by the
    weight. Relevant only in the top level menu items.

### `custom`

Menu item with any command

Attributes

  - `name`: {String, required} Name of the item
  - `command`: {Array, required} Command to execute
  - `installer`: {String, optional} Path to an alternative executable. Used as
    the `command` when it's not found from the PATH.

### `desktop`

Launcher item from a .desktop file. It auto populates `id`, `name`,
`description`, `command` and `osIcon` attributes. Any auto populated field can
be overridden by specifying it directly to this object. If the requested
`.desktop` file is not found the item will not be displayed. Respects the current
locale.

Desktop file locations are configured in `config.json`.

  - `source`: {String, required} Name of the .desktop file without the extension
  - `installer`: {String, optional} Used as the command when the .desktop file
    is not found from the system

#### `desktop.d` directories

As of Webmenu `0.8.0` the desktop entries can be defined in following
`desktop.d` directories as JSON and YAML:

  1. `~/.config/webmenu/desktop.d/*.{json,yaml}`
  2. `/etc/webmenu/desktop.d/*.{json,yaml}`

Each file must have a object of `.desktop` filenames (without an extension) as
keys. It can be used to override some or all the values of a desktop file – or
create completely new entries.

Files are read alphabetically. Entries in latter ones will override any
existing entries.

Example: Override the name in `gedit.desktop`

`~/.config/webmenu/desktop.d/gedit-override.json`

```js
{
  "gedit": {
    "name": {
      "en": "Simple editor",
      "fi": "Yksinkertainen editori"
  }
}
```

Example: Create completely new entry

`~/.config/webmenu/desktop.d/myapps.json`

```js
{
  "eyes": {
    "name": "Show some eyes",
    "osIcon": "myicon",
    "command": "xeyes"
  }
}
```


### `web`

Open web link using `xdg-open`

Attributes

  - `name`: {String, required} Name of the item
  - `url`: {String, required} Url to open

### `webWindow`

Open web link in a chromeless browser window without menu and address bars

Attributes

  - `name`: {String, required} Name of the item
  - `url`: {String, required} Url to open
  - `width`: {Integer, optional} Width in pixels
  - `height`: {Integer, optional} height in pixels

**WARNING** Use with caution. This causes the web page to be run in the same
instance as the menu which means if the web site crashes it might crash the
menu too. Also the security implications are not well understood. This should
be only used with sites you trust 100%.

For more secure web window solution you can use Chrome (or `chromium-browser`)
with the `--app` switch via the custom type.

```json
{
  "type": "custom",
  "name": "My windowed web app",
  "command": ["chromium-browser", "--app=http://example.com/"],
  "osIconPath": "path-to-icon"
}
```

You might want to specify `--user-data-dir=DIR` too if you want separate
cookies from the actual browser instance.

### Common attributes

These attributes can be added to any object

  - `description`: {String, optional} Description of the item or menu
  - `osIcon`: {String, optional} Icon from the operating system theme
  - `osIconPath`: {String, optional} Absolute or relative path from Webmenu
    installation directory to a icon file
    - Example absolute: `/usr/share/icons/Faenza/apps/96/me-tv.png`
    - Example relative `extra/icons/apps/youtube.png`
  - `cssIcon`: {String, optional} CSS icon class from [font-awesome][].
    Overrides `osIcon`
  - `keywords`: {Array} Array of strings. Make item appear also when on these
    search strings.
  - `condition`: {String, optional} Javascript expression. When present the
  condition is executed and the item will appear only when the expression
  evaluates to a truthty value. The expression has two values in scope. `env`
  which contains all the environment environment and `item` which is the current
  menu item.

### Translations

Item `name` and `description` attributes can be translated using a translation
object instead of a plain string.

Example:

```json
{
  "en": "Calculator",
  "fi": "Laskin"
}
```

menu.json example: <https://github.com/opinsys/webmenu/commit/bd75038be2dbe07e67f485f2277b180ef9fea82c#L0L4>

[font-awesome]: http://fortawesome.github.com/Font-Awesome/

