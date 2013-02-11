
# menu.json

Menu content is created from a menu.json file. Webmenu will look it from
following locations:

  1. ~/.config/webmenu/menu.json
  2. /etc/webmenu/menu.json
  3. the bundled menu.json

In future Webmenu will be able to fetch it from a web service.

## Structure

menu.json is a nested object presentation of menus and launchable items.

Every object must have a `type` attribute which can be one of following:


### `menu`

Menu object contains all the menu items. This is the root object, but it can
also contain other menu objects.

Attributes

  - `name`: {String, required} Name of the item
  - `items`: {Array, required} Array of item and/or menu objects

### `custom`

Menu item with any command

Attributes

  - `name`: {String, required} Name of the item
  - `command`: {Array, required} Command to execute

### `desktop`

Menu item from a .desktop file. It auto populates `name`, `description`,
`command` and `osIcon` attributes. Any auto populated field can be overridden
by specifying it directly to this object. If the requested .desktop file is not
found the item will not be displayed. Respects the current locale.

Desktop file locations are configured in `config.json`

  - `id`: {String, required} Name of the .desktop file without the extension


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
  - `Height`: {Integer, optional} height in pixels


### Common attributes

These attributes can be added to any object

  - `description`: {String, optional} Description of the item or menu
  - `osIcon`: {String, optional} Icon from the operating system theme
  - `osIconPath`: {String, optional} Absolute or relative path from Webmenu
    installation directory to a icon file
  - `cssIcon`: {String, optional} CSS icon class from [font-awesome][].
    Overrides `osIcon`


[font-awesome]: http://fortawesome.github.com/Font-Awesome/

