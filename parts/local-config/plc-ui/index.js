var child_process = require('child_process');
var fs = require('fs');
var gui = require('nw.gui');

var config_json_dir  = '/state/etc/puavo/local';
var config_json_path = config_json_dir + '/config.json';
var old_config;

var locale = process.env.LANG.substring(0, 2);

var mc =
  function(msg) {
    translations = {
      fi: {
        'Laptop configuration': 'Kannettavan asetukset',

        'Additional software installation': 'Lisäohjelmistojen asennus',

        'The following software have licenses that do not allow preinstallation.  You can install them from here, but by installing you accept the software license terms.  Note!  Software installation requires network connection.  Software installation may take several minutes.  Closing the window will interrupt installation.':
          'Lisäohjelmistot ovat sovelluksia, joita ei ole lisenssiehtojen vuoksi voitu asentaa kannettavalle valmiiksi.  Voit asentaa tarvitsemiasi ohjelmistoja tästä ja samalla hyväksyt niiden lisenssiehdot.  Huom!  Ohjelmistojen asennus vaatii verkkoyhteyden.  Ohjelmistojen asentaminen voi kestää useita minuutteja.  Ikkunan sulkeminen keskeyttää asennuksen.',

        'ACCEPT ALL LICENSES AND INSTALL ALL SOFTWARE.':
           'HYVÄKSY KAIKKI LISENSSIT JA ASENNA KAIKKI OHJELMAT.',

        'INSTALL':         'ASENNA',
        'Installing...':   'Asennetaan...',
        'license terms':   'lisenssiehdot',
        'Uninstalling...': 'Poistetaan...',
        'UNINSTALL':       'POISTA',

        'Error in installation, check network.':
           'Asennus ei onnistunut, tarkista verkkoyhteys.',

        'Error in installation, unknown reason.':
           'Asennus ei onnistunut, tuntematon syy.',

        'Closing this application will interrupt software installation/uninstallation, are you sure you want to quit?':
          'Tämän ohjelman sulkeminen keskeyttää sovelluksien asennuksien/poiston, haluatko varmasti sulkea ohjelman?',

        'Access controls': 'Pääsyoikeudet',

        'Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at ':
          'Pääsyoikeuksilla määritetään käyttäjätunnukset, joilla on laitteen pääkäyttäjän lisäksi pääsy tälle tietokoneelle.  Uusia käyttäjätunnuksia voit luoda osoitteessa ',

        'Allow all users from "lukiolaiskannettava"-domain.':
          'Salli kaikkien lukiolaiskannettavatunnusten kirjautuminen',

        'Allow only the following usernames:':
          'Salli vain seuraavat lukiolaiskannettavatunnukset:',

        'Automatic updates':
          'Järjestelmäpäivitykset',

        'Automatic system updates keep your systems up-to-date and secure.  You can also update manually.':
          'Automaattiset järjestelmäpäivitykset pitävät tietokoneesi ajan tasalla ja tietoturvallisena.  Voit päivittää myös käsin.',

        'Enable automatic updates':
          'Tee järjestelmäpäivitykset automaattisesti',

        'You do not have permission to run this tool':
          'Sinulla ei ole tarvittavia oikeuksia tämän työkalun käyttöön',
      },
      sv: {
        'Laptop configuration': 'Laptop configuration', // XXX

        'Additional software installation': 'Additional software installation', // XXX

        'The following software have licenses that do not allow preinstallation.  You can install them from here, but by installing you accept the software license terms.  Note!  Software installation requires network connection.  Software installation may take several minutes.  Closing the window will interrupt installation.':
         'The following software have licenses that do not allow preinstallation.  You can install them from here, but by installing you accept the software license terms.  Note!  Software installation requires network connection.  Software installation may take several minutes.  Closing the window will interrupt installation.', // XXX

        'ACCEPT ALL LICENSES AND INSTALL ALL SOFTWARE.':
          'ACCEPT ALL LICENSES AND INSTALL ALL SOFTWARE.', // XXX

        'INSTALL':         'INSTALLERA',
        'Installing...':   'Installering...',
        'license terms':   'licensvillkor',
        'Uninstalling...': 'Avinstallering...',
        'UNINSTALL':       'AVINSTALLERA',

        'Error in installation, check network.':
          'Error in installation, check network.', // XXX

        'Error in installation, unknown reason.':
          'Error in installation, unknown reason.', // XXX

        'Closing this application will interrupt software installation/uninstallation, are you sure you want to quit?':
          'Closing this application will interrupt software installation/uninstallation, are you sure you want to quit?',

        'Access controls': 'Access controls', // XXX

        'Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at ':
          'Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at ', // XXX

        'Allow all users from "lukiolaiskannettava"-domain.':
          'Allow all users from "lukiolaiskannettava"-domain.', // XXX

        'Allow only the following usernames:':
          'Allow only the following usernames:', // XXX

        'Automatic updates':
          'Automatic updates', // XXX

        'Automatic system updates keep your systems up-to-date and secure.  You can also update manually.':
          'Automatic system updates keep your systems up-to-date and secure.  You can also update manually.', // XXX

        'Enable automatic updates':
          'Enable automatic updates', // XXX

        'You do not have permission to run this tool':
          'Du har inte rättigheter för att köra det här verktyget',
      },
    }

    return (translations[locale] && translations[locale][msg])
              || msg;
  };

function PkgInstaller(button, initial_state, pkgname, errormsg_element) {
  this.button           = button;
  this.button_state     = initial_state;
  this.errormsg_element = errormsg_element;
  this.pkgname          = pkgname;

  this.styles = {
    install:        'background-color: orange',
    installing_a:   'background-color: yellow',
    installing_b:   'background-color: white',
    uninstall:      'background-color: lightgreen',
    uninstalling_a: 'background-color: red',
    uninstalling_b: 'background-color: yellow',
  };

  this.flash_interval = null;
  this.previous_eventhandler = null;

  this.operation_in_progress = false;

  if (this.button_state === 'press_install') {
    this.button_state_press_install();
  } else if (this.button_state === 'press_uninstall') {
    this.button_state_press_uninstall();
  }
}

PkgInstaller.prototype = {
  // button state setup methods first
  button_state_press_install:
    function() {
      var pkginstaller = this;
      this.operation_in_progress = false;
      this.button_state = 'press_install';
      this.button.textContent = mc('INSTALL');
      this.button.setAttribute('style', this.styles.install);
      this.operation_in_progress = false;
      this.setup_action(function(e) { e.preventDefault();
                                      pkginstaller.install(); });
    },

  button_state_installing:
    function() {
      var pkginstaller = this;
      this.button_state = 'installing';
      this.button.textContent = mc('Installing...');
      this.button.setAttribute('style', this.styles.installing_a);
      this.operation_in_progress = true;
      this.setup_action(function(e) { e.preventDefault(); });
      this.flash_interval
        = setInterval(function() {
                        pkginstaller.make_flashes('installing_a',
                                                  'installing_b'); },
                      500);
    },

  button_state_press_uninstall:
    function() {
      var pkginstaller = this;
      this.button_state = 'press_uninstall';
      this.button.textContent = mc('UNINSTALL');
      this.button.setAttribute('style', this.styles.uninstall);
      this.operation_in_progress = false;
      this.setup_action(function(e) { e.preventDefault();
                                      pkginstaller.uninstall(); });
    },

  button_state_uninstalling:
    function() {
      var pkginstaller = this;
      this.button_state = 'uninstalling';
      this.button.textContent = mc('Uninstalling...');
      this.button.setAttribute('style', this.styles.uninstalling_a);
      this.operation_in_progress = true;
      this.setup_action(function(e) { e.preventDefault(); });
      this.flash_interval
        = setInterval(function() {
                        pkginstaller.make_flashes('uninstalling_a',
                                                  'uninstalling_b'); },
                      200);
    },

  // helper methods for dealing with UI

  setup_action:
    function(fn) {
      if (this.flash_interval) {
        clearInterval(this.flash_interval);
        this.flash_interval = null;
      }
      if (this.previous_eventhandler) {
        this.button.removeEventListener('click', this.previous_eventhandler);
      }
      this.button.addEventListener('click', fn);
      this.previous_eventhandler = fn;
    },

  make_flashes:
    function(a, b) {
      if (this.button.getAttribute('style') === this.styles[a]) {
        this.button.setAttribute('style', this.styles[b]);
      } else if (this.button.getAttribute('style') === this.styles[b]) {
        this.button.setAttribute('style', this.styles[a]);
      }
    },

  // the install/uninstall methods

  install:
    function() {
      // this might be called indirectly
      if (this.button_state !== 'press_install') { return; }

      var pkginstaller = this;
      handle_pkg('install',
                 this.pkgname,
                 this.errormsg_element,
                 function(error) { pkginstaller.install_returned(error); });
      this.operation_in_progress = true;
      this.button_state_installing();
    },

  uninstall:
    function() {
      if (this.button_state !== 'press_uninstall') { return; }

      var pkginstaller = this;
      handle_pkg('uninstall',
                 this.pkgname,
                 this.errormsg_element,
                 function(error) { pkginstaller.uninstall_returned(error); });
      this.operation_in_progress = true;
      this.button_state_uninstalling();
    },

  // callback methods for install/uninstall

  install_returned:
    function(error) {
      if (error) {
        this.button_state_press_install();
      } else {
        this.button_state_press_uninstall();
      }
    },

  uninstall_returned:
    function(error) {
      if (error) {
        this.button_state_press_uninstall();
      } else {
        this.button_state_press_install();
      }
    },
}

function activate_window(win) {
  win.show();
  win.focus();

  // This is a hack to get window to raise above other windows
  // (I could not find other way with node-webkit 0.8.6).
  win.enterFullscreen(); win.leaveFullscreen();
}

function add_pkginstaller(pkgname, errormsg_element, sw_state) {
  var button = document.createElement('button');

  button_state = (sw_state !== 'INSTALLED')
                    ? 'press_install'
                    : 'press_uninstall';

  return new PkgInstaller(button, button_state, pkgname, errormsg_element);
}

function add_one_pkginstaller(parentNode,
                              description,
                              legend,
                              license_url,
                              pkgname,
                              sw_state) {
  var tr = document.createElement('tr');

  // create legend element
  var legend_td = document.createElement('td');
  legend_td.textContent = legend;
  if (description !== '') { legend_td.setAttribute('tooltip', description); }
  tr.appendChild(legend_td);

  // create license url link
  var license_url_td = document.createElement('td');
  var a = document.createElement('a');
  a.setAttribute('href', license_url);
  a.addEventListener('click',
                     function(e) { e.preventDefault();
                                   open_external_link(a); });
  a.textContent = mc('license terms');
  tr.appendChild( license_url_td.appendChild(a) );

  // create action button and error element
  var action_td = document.createElement('td');
  var action_errormsg_element = document.createElement('td');
  pkginstaller = add_pkginstaller(pkgname, action_errormsg_element, sw_state);
  action_td.appendChild(pkginstaller.button);

  tr.appendChild(action_td);
  tr.appendChild(action_errormsg_element);

  parentNode.appendChild(tr);

  return pkginstaller;
}

function add_pkginstallers(table, packages) {
  var pkginstallers_list = [];

  var add_each_pkgcontrol
    = function (sw_states) {
        sorted_pkgnames = Object.keys(packages).sort(
          function (a, b) {
            norm_a = (packages[a].legend || a).toLowerCase();
            norm_b = (packages[b].legend || b).toLowerCase();
            return (norm_a < norm_b) ? -1 : 1;
          });

        for (var i in sorted_pkgnames) {
          var pkgname = sorted_pkgnames[i];

          var description = packages[pkgname].description;
          var legend      = packages[pkgname].legend;

          if (!description || description.match(/^\s+$/)) { description = ''; }
          if (!legend      || legend.match(/^\s+$/))      { legend      = ''; }

          var license_url = packages[pkgname].license_url;
          if (!license_url) {
            alert('Package ' + pkgname + ' is missing license url');
            continue;
          }

          var pkginstaller = add_one_pkginstaller(table,
                                                  description,
                                                  legend,
                                                  license_url,
                                                  pkgname,
                                                  sw_states[pkgname]);
          pkginstallers_list.push(pkginstaller);
        }
      };

  check_software_states(add_each_pkgcontrol, Object.keys(packages));

  return pkginstallers_list;
}

function check_access() {
  // make sure only admins can use this tool (this is just a gui niceness)
  var access_ok;
  try {
    fs.readdirSync(config_json_dir);
    access_ok = true;
  } catch(ex) {
    access_ok = false;
  };

  if (!access_ok) {
    alert( mc('You do not have permission to run this tool') );
    process.exit(1);
  }
}

function check_software_states(cb, available_packages) {
  var sw_states = {};

  // packages are uninstalled unless "puavo-pkg list" proves otherwise (below)
  for (var i in available_packages) {
    sw_states[ available_packages[i] ] = 'UNINSTALLED';
  }

  var handler
    = function (error, stdout, stderr) {
        if (error) { throw(error); }

        stdout.toString()
              .split("\n")
              .forEach(function (line) {
                         if (line !== '') {
                           fields = line.split(/\s+/);
                           var pkgname = fields[0];
                           sw_states[pkgname] = 'INSTALLED';
                         }
                       });

        cb(sw_states);
      };

  child_process.execFile('puavo-pkg',
                         [ 'list' ],
                         {},
                         handler);
}

function create_error_details(shorttext, message) {
  var details = document.createElement('details');

  var summary = document.createElement('summary');
  summary.textContent = shorttext;
  details.appendChild(summary);

  var errmsgblock = document.createElement('pre');
  errmsgblock.textContent = message;
  details.appendChild(errmsgblock);

  return details;
}

function generate_allow_logins_input(form) {
  var table = document.createElement('table');

  var make_radiobutton
    = function(tr, value, text, checked, last_cell_spanvalue) {
        var input = document.createElement('input');
        if (checked) {
          input.setAttribute('checked', true);
        } else {
          input.removeAttribute('checked');
        }
        var input_id = 'allow_logins_for_radio_' + value;
        input.setAttribute('id', input_id);
        input.setAttribute('name', 'allow_logins_for');
        input.setAttribute('type', 'radio');
        input.setAttribute('value', value);
        input.addEventListener('click', write_config);

        var tr = table.appendChild( document.createElement('tr') );
        var td = tr   .appendChild( document.createElement('td') );
        if (last_cell_spanvalue !== 1) { td.colSpan = last_cell_spanvalue; }
        td.appendChild(input);

        var label = document.createElement('label');
        label.textContent = text;
        label.setAttribute('for', input_id);
        td.appendChild(label);

        return tr;
      };

  var all_is_chosen = (old_config.allow_logins_for.indexOf('*') >= 0);

  make_radiobutton(table,
                   'all_puavo_domain_users',
                   mc('Allow all users from "lukiolaiskannettava"-domain.'),
                   all_is_chosen,
                   2);

  var rb_tr = make_radiobutton(table,
                               'some_puavo_domain_users',
                               mc('Allow only the following usernames:'),
                               !all_is_chosen);

  var allowed_puavo_users = old_config.allow_logins_for
                              .filter(function(s) { return s !== '*'; });
  make_listwidgets(rb_tr, 'allowed_puavo_users', allowed_puavo_users);

  var title = document.createElement('div');
  var link = document.createElement('a');
  link.textContent = 'lukiolaiskannettava.opinsys.fi/accounts';
  link.setAttribute('href', 'https://lukiolaiskannettava.opinsys.fi/accounts');
  link.addEventListener('click',
			function(e) { e.preventDefault();
                                      open_external_link(link); });
  var description = document.createTextNode(mc('Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at '));
  title.appendChild(description);
  title.appendChild(link);
  title.appendChild(document.createTextNode('.'));
  title.appendChild(table);

  form.appendChild(title);
}

function generate_form() {
  var form = document.querySelector('form[id=dynamic_form]');

  // software installation
  var pkginstallers = generate_software_installation_controls(form);

  // login-access control
  generate_loginaccess_controls(form);

  // automatic-updates controls
  generate_automatic_update_controls(form);

  return pkginstallers;
}

function generate_automatic_update_controls(form) {
  var title = document.createElement('h2');
  title.textContent = mc('Automatic updates');
  form.appendChild(title);

  var div = document.createElement('div');

  var description_div = document.createElement('div');
  var description_text
    = document.createTextNode( mc('Automatic system updates keep your systems up-to-date and secure.  You can also update manually.') );
  description_div.appendChild(description_text);

  var input_id = 'automatic_image_updates_checkbox';
  var label = document.createElement('label');
  label.textContent = mc('Enable automatic updates');
  label.setAttribute('for', input_id);

  var input = document.createElement('input');
  input.setAttribute('id', input_id);
  input.setAttribute('name', 'automatic_image_updates');
  input.setAttribute('type', 'checkbox');
  if (old_config.automatic_image_updates) {
    input.setAttribute('checked', true);
  } else {
    input.removeAttribute('checked');
  }
  input.addEventListener('click', write_config);

  div.appendChild(description_div);
  div.appendChild(input);
  div.appendChild(label);

  form.appendChild(div);
}

function generate_loginaccess_controls(form) {
  var title = document.createElement('h2');
  title.textContent = mc('Access controls');
  form.appendChild(title);

  generate_allow_logins_input(form);
}

function generate_software_installation_controls(form) {
  var packages = get_packages();
  if (Object.keys(packages).length === 0) { return; }

  var title = document.createElement('h2');
  title.textContent = mc('Additional software installation');
  form.appendChild(title);

  var textdiv = document.createElement('div');
  textdiv.textContent = mc('The following software have licenses that do not allow preinstallation.  You can install them from here, but by installing you accept the software license terms.  Note!  Software installation requires network connection.  Software installation may take several minutes.  Closing the window will interrupt installation.');
  textdiv.setAttribute('style', 'margin-bottom: 0.6em; margin-top: 0.8em;');
  form.appendChild(textdiv);

  var pkgcontrols_table = document.createElement('table');
  var pkginstallers = add_pkginstallers(pkgcontrols_table, packages);

  var install_all_button = document.createElement('button');
  install_all_button.setAttribute('style', 'background-color: orange');
  install_all_button.textContent
    = mc('ACCEPT ALL LICENSES AND INSTALL ALL SOFTWARE.');
  install_all_button.addEventListener(
    'click',
    function(e) { e.preventDefault();
                  for (i in pkginstallers) {
                    pkginstallers[i].install();
                  }
                });

  form.appendChild(install_all_button);
  form.appendChild(pkgcontrols_table);

  return pkginstallers;
}

function get_packages() {
  packages_json_path = '/images/puavo-pkg/installers/installers/packages.json';

  try {
    return JSON.parse( fs.readFileSync(packages_json_path) );
  } catch(ex) {
    alert('Could not read the list of additional software packages: ' + ex);
    return {};
  }
}

function handle_close_request(win) {
  var some_pkginstallation_in_progress = false;

  for (i in pkginstallers) {
    var pkginstaller = pkginstallers[i];
    if (pkginstaller.operation_in_progress) {
      some_pkginstallation_in_progress = true;
    }
  }

  if (some_pkginstallation_in_progress) {
    var text = 'Closing this application will interrupt software installation/uninstallation, are you sure you want to quit?';
    var we_have_confirmation = confirm(mc(text));
    if (!we_have_confirmation) {
      return;
    }
  }

  win.close(true);
}

function handle_pkg(mode, pkgname, errormsg_element, cb) {
  cmd_mode = (mode === 'install' ? '--install-pkg' : '--remove-pkg');
  var cmd_args = [ '/usr/sbin/puavo-local-config', cmd_mode, pkgname ];

  var handler
    = function(error, stdout, stderr) {
        if (error) {
          if (error.code === 2) {
            var details
              = create_error_details(
                  mc('Error in installation, check network.'),
                  stderr);
            errormsg_element.appendChild(details);
          } else {
            var details
              = create_error_details(
                  mc('Error in installation, unknown reason.'),
                  stderr);
            errormsg_element.appendChild(details);
          }
        } else {
          errormsg_element.textContent = '';
        }

        // Error or not, some package may have been installed or uninstalled
        // now, so we trigger "puavo-webmenu --daemon --log" so that webmenu
        // will pick up the changes.
        // XXX Note that perhaps we should actually confirm somehow that
        // XXX webmenu is installed and active on the desktop...
        // XXX (and this trigger probably does not belong to this level
        // XXX anyway, in case installations/uninstallations happen without
        // XXX this tool).
        opts = {
          cwd: '/',             // XXX Needed, because otherwise webmenu thinks
                                // XXX it is running in development environment
                                // XXX (fix webmenu).
          detached: true,
          stdio: 'ignore',
        }
        var child = child_process.spawn('puavo-webmenu',
                                        [ '--daemon', '--log' ],
                                        opts);
        child.unref();

        cb(error);
      };

  errormsg_element.textContent = '';

  // buffer program output up to 2Mb (fails if there is more output)
  options = { maxBuffer: (2 * 1024 * 1024) };
  child_process.execFile('sudo', cmd_args, options, handler);
}

function make_listwidgets(parentNode, fieldname, initial_values) {
  var listwidgets = [];

  var make_listwidget
    = function(value) {
        var check_mark = '&#x2714';

        var table    = document.createElement('table');
        var tr       = table   .appendChild( document.createElement('tr')    );
        var input_td = tr      .appendChild( document.createElement('td')    );
        var ok_mark  = tr      .appendChild( document.createElement('td')    );
        var input    = input_td.appendChild( document.createElement('input') );

        input.setAttribute('name', fieldname);
        input.setAttribute('type', 'text');
        input.setAttribute('value', value);
        input.addEventListener('focusout', function(e) {
                                             update_listwidgets();
                                             write_config(); });

        if (input.value !== '') { ok_mark.innerHTML = check_mark; }

        // Do not activate the first button (might be "install all software"),
        // when enter is pressed on some input field.
        input.addEventListener('keypress',
                               function(e) {
                                 if (e.keyCode === 13) {
                                   e.preventDefault();
                                   input.blur();
                                 }
                               });

        input.addEventListener('keyup',
                               function(e) {
                                 ok_mark.innerHTML = '';
                                 write_config();
                                 if (input.value !== '') {
                                   ok_mark.innerHTML = check_mark;
                                 }
                                 update_listwidgets();
                               });

        ok_mark.setAttribute('style', 'color: green;');

        parentNode.appendChild(table);

        return { input: input, table: table, };
      };

  var update_listwidgets
    = function() {
        var one_empty_listwidget = false;

        for (i in listwidgets) {
          if (listwidgets[i].input.value.match(/^\s*$/)) {
            if (one_empty_listwidget) {
              var table = listwidgets[i].table;
              delete listwidgets[i];
              table.parentNode.removeChild(table);
            } else {
              one_empty_listwidget = true;
            }
          }
        }

        if (!one_empty_listwidget) {
          listwidgets.push( make_listwidget('') );
        }
      };

  for (v in initial_values)
    listwidgets.push( make_listwidget(initial_values[v]) );

  update_listwidgets();
}

function open_external_link(e) {
  var child = child_process.spawn('chromium-browser',
                                  [ '--app=' + e.href,
                                    '--window-position=480,60',
                                    '--window-size=640,580' ],
                                  { detached: true, stdio: 'ignore' });
  child.unref();
}

function read_config() {
  var config;

  try {
    config = JSON.parse( fs.readFileSync(config_json_path) );
    if (!config.version || config.version != 2) {
      alert('Configuration file ' + config_json_path
              + ' is on an unknown version, refusing to do anything.')
      return false;
    }
  } catch (ex) {
    if (ex.code === 'ENOENT') {
      // default config in case everything is missing
      config = {
        allow_logins_for:        [],
        automatic_image_updates: true,
        version:                 2,
      };
      write_config_to_file(config);
    } else {
      alert(ex);
      return false;
    }
  }

  return config;
}

function write_config() {
  var response = document.forms[0].elements;
  var new_config = {
    allow_logins_for:        [],
    automatic_image_updates: true,
    version:                 2,
  };

  switch(response.allow_logins_for.value) {
    case 'all_puavo_domain_users':
      new_config.allow_logins_for = [ '*' ];
      break;
    case 'some_puavo_domain_users':
      allowed_puavo_users
        = (response.allowed_puavo_users.constructor === HTMLInputElement)
            ? [ response.allowed_puavo_users ]
            : response.allowed_puavo_users;
      for (i in allowed_puavo_users) {
        var user = allowed_puavo_users[i].value;
        if (user && user.match(/\S+/)) {
          new_config.allow_logins_for.push(user);
        }
      }

      break;
  }

  new_config.automatic_image_updates
     = response.automatic_image_updates.checked;

  write_config_to_file(new_config);
}

function write_config_to_file(conf) {
  try {
    var data = JSON.stringify(conf) + "\n";
    var tmpfile = config_json_path + '.tmp';
    fs.writeFileSync(tmpfile, data);
    fs.renameSync(tmpfile, config_json_path);
  } catch (ex) { alert(ex); throw(ex); }
}


check_access();         // will exit in case of errors

old_config = read_config();
if (!old_config) { process.exit(1); }

// set document titles
document.querySelector('title').innerText = mc('Laptop configuration');
document.querySelector('h1'   ).innerText = mc('Laptop configuration');

var pkginstallers = generate_form();

var win = gui.Window.get();

process.on('SIGHUP', function() { activate_window(win) });
win.on('close', function() { handle_close_request(win, pkginstallers); });
