# menu.json

Menu content is created from a menu.json file. Webmenu will look it from
following locations:

  1. ~/.config/webmenu/menu.json
  2. /etc/webmenu/menu.json
  3. the bundled menu.json

Use these paths to customize Webmenu content.

In future Webmenu will be able to fetch it from a web service.

## Structure

menu.json is a nested object presentation of menus and launchable items.

Every object must have a `type` attribute which can be one of following:


### `menu`

Menu object contains all the menu items. This is the root object, but it can
also contain other menu objects.

Attributes

  - `name`: {String, required} Name of the item
  - `items`: {Array, required} Array of launcher object and/or menu objects

### `custom`

Menu item with any command

Attributes

  - `name`: {String, required} Name of the item
  - `command`: {Array, required} Command to execute

### `desktop`

Launcher item from a .desktop file. It auto populates `id`, `name`,
`description`, `command` and `osIcon` attributes. Any auto populated field can
be overridden by specifying it directly to this object. If the requested
.desktop file is not found the item will not be displayed. Respects the current
locale.

Desktop file locations are configured in `config.json`.

  - `source`: {String, required} Name of the .desktop file without the extension


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

