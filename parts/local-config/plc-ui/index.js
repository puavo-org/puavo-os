var child_process = require('child_process');
var fs = require('fs');

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

        'Access controls': 'Pääsyoikeudet',

        'Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at ':
          'Pääsyoikeuksilla määritetään käyttäjätunnukset, joilla on laitteen pääkäyttäjän lisäksi pääsy tälle tietokoneelle.  Uusia käyttäjätunnuksia voit luoda osoitteessa ',

        'Allow all users from "lukiolaiskannettava"-domain.':
          'Salli kaikkien lukiolaiskannettavatunnusten kirjautuminen',

        'Allow only the following usernames:':
          'Salli vain seuraavat lukiolaiskannettavatunnukset:',

        'Remote assistance': 'Etätuki',

        'If you want to allow Opinsys support service to remotely access your computer, you can do that with this option.  This setting will reset when computer reboots.':
          'Mikäli haluat sallia Opinsysin tukipalvelun etäpääsyn tietokoneellesi tukitilanteessa, voit tehdä sen tällä valinnalla.  Tämä asetus nollautuu laitteen uudelleenkäynnistyksen yhteydessä.',

        'Allow remote assistance': 'Salli etätuki',

        'Configuration needs corrections, no changes are saved.':
          'Asetukset vaativat korjausta, muutokset eivät tallennu.',

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

        'Access controls': 'Access controls', // XXX

        'Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at ':
          'Access controls determine the login names that have access to this computer in addition to the primary user.  New login names can be created at ', // XXX

        'Allow all users from "lukiolaiskannettava"-domain.':
          'Allow all users from "lukiolaiskannettava"-domain.', // XXX

        'Allow only the following usernames:':
          'Allow only the following usernames:', // XXX

        'Remote assistance': 'Remote assistance', // XXX

        'If you want to allow Opinsys support service to remotely access your computer, you can do that with this option.  This setting will reset when computer reboots.':
          'If you want to allow Opinsys support service to remotely access your computer, you can do that with this option.  This setting will reset when computer reboots.', // XXX

        'Allow remote assistance': 'Allow remote assistance', // XXX

        'Configuration needs corrections, no changes are saved.':
          'Inställningarna kräver korrigering, inga ändringar har sparats',

        'You do not have permission to run this tool':
          'Du har inte rättigheter för att köra det här verktyget',
      },
    }

    return (translations[locale] && translations[locale][msg])
              || msg;
  };

function add_action_button(pkgname, errormsg_element, sw_state) {
  var button = document.createElement('button');

  button_state = (sw_state !== 'INSTALLED')
                    ? 'press_install'
                    : 'press_uninstall';

  var install_pkg_fn
    = create_action_button_with_initial_state(button,
                                              button_state,
                                              pkgname,
                                              errormsg_element);

  return { button: button, install_pkg_fn: install_pkg_fn };
}

function add_software_controls(table, packages) {
  var install_pkg_functions = [];

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

          var install_pkg_fn = add_one_pkgcontrol(table,
                                                  description,
                                                  legend,
                                                  license_url,
                                                  sw_states[pkgname]);
          install_pkg_functions.push(install_pkg_fn);
        }
      };

  check_software_states(add_each_pkgcontrol, Object.keys(packages));

  return install_pkg_functions;
}

function add_one_pkgcontrol(parentNode,
                            description,
                            legend,
                            license_url,
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
  button_and_install_action = add_action_button(legend,
                                                action_errormsg_element,
                                                sw_state);
  action_td.appendChild(button_and_install_action.button);

  tr.appendChild(action_td);
  tr.appendChild(action_errormsg_element);

  parentNode.appendChild(tr);

  return button_and_install_action.install_pkg_fn;
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

function create_action_button_with_initial_state(button,
                                                 initial_state,
                                                 pkgname,
                                                 errormsg_element) {
  /* XXX we could make this a real class instead? */

  var styles = {
    install:        'background-color: orange',
    installing_a:   'background-color: yellow',
    installing_b:   'background-color: white',
    uninstall:      'background-color: lightgreen',
    uninstalling_a: 'background-color: red',
    uninstalling_b: 'background-color: yellow',
  };

  var flash_interval, previous_eventhandler;
  var setup_action = function(fn) {
    if (flash_interval) {
      clearInterval(flash_interval);
      flash_interval = null;
    }
    if (previous_eventhandler) {
      button.removeEventListener('click', previous_eventhandler);
    }
    button.addEventListener('click', fn);
    previous_eventhandler = fn;
  };

  var make_flashes
    = function(a, b) {
        if (button.getAttribute('style') === styles[a]) {
          button.setAttribute('style', styles[b]);
        } else if (button.getAttribute('style') === styles[b]) {
          button.setAttribute('style', styles[a]);
        };
      };

  var install_returned
    = function(error) {
        state_functions[ !error ? 'press_uninstall' : 'press_install' ]();
      };

  var uninstall_returned
    = function(error) {
        state_functions[ !error ? 'press_install' : 'press_uninstall' ]();
      };

  var button_state = initial_state;

  var state_functions = {
    installing:
      function() {
        button_state = 'installing';
        button.textContent = mc('Installing...');
        button.setAttribute('style', styles.installing_a);
        setup_action(function(e) { e.preventDefault(); });
        flash_interval
          = setInterval(function () { make_flashes('installing_a',
                                                   'installing_b'); },
                        500);
      },
    uninstalling:
      function() {
        button_state = 'uninstalling';
        button.textContent = mc('Uninstalling...');
        button.setAttribute('style', styles.uninstalling_a);
        setup_action(function(e) { e.preventDefault(); });
        flash_interval
          = setInterval(function () { make_flashes('uninstalling_a',
                                                   'uninstalling_b'); },
                        200);
      },
  };

  var install_fn = function() {
                     handle_pkg('install',
                                pkgname,
                                errormsg_element,
                                install_returned);
                     state_functions.installing();
                   };

  var uninstall_fn = function() {
                       handle_pkg('uninstall',
                                  pkgname,
                                  errormsg_element,
                                  uninstall_returned);
                       state_functions.uninstalling();
                     };

  state_functions.press_install
    = function() {
        button_state = 'press_install';
        button.textContent = mc('INSTALL');
        button.setAttribute('style', styles.install);
        setup_action(function(e) { e.preventDefault(); install_fn(); });
      };
  state_functions.press_uninstall
    = function() {
        button_state = 'press_uninstall';
        button.textContent = mc('UNINSTALL');
        button.setAttribute('style', styles.uninstall);
        setup_action(function(e) { e.preventDefault(); uninstall_fn(); });
      };

  state_functions[initial_state]();

  // return a function that enables pressing "install" if in such a state
  return function() {
    if (button_state === 'press_install') {
      install_fn();
    }
  }
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

  // .slice(0) clones a list (just in case)
  var allowed_puavo_users = old_config.allow_logins_for.slice(0);
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

function generate_allow_remoteadmins_input(form) {
  var div = document.createElement('div');

  var description_div = document.createElement('div');
  var description_text
    = document.createTextNode( mc('If you want to allow Opinsys support service to remotely access your computer, you can do that with this option.  This setting will reset when computer reboots.') );
  description_div.appendChild(description_text);

  var input_id = 'allow_remoteadmins_checkbox';
  var label = document.createElement('label');
  label.textContent = mc('Allow remote assistance');
  label.setAttribute('for', input_id);

  var input = document.createElement('input');
  input.setAttribute('id', input_id);
  input.setAttribute('name', 'allow_remoteadmins');
  input.setAttribute('type', 'checkbox');
  if (old_config.allow_remoteadmins) {
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

function generate_form() {
  var form = document.querySelector('form[id=dynamic_form]');

  // software installation
  generate_software_installation_controls(form);

  // login-access control
  generate_loginaccess_controls(form);
}

function generate_loginaccess_controls(form) {
  var title = document.createElement('h2');
  title.textContent = mc('Access controls');
  form.appendChild(title);

  generate_allow_logins_input(form);

  var subtitle = document.createElement('h3');
  subtitle.textContent = mc('Remote assistance');
  form.appendChild(subtitle);

  generate_allow_remoteadmins_input(form);
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
  var install_pkg_functions = add_software_controls(pkgcontrols_table,
                                                    packages);

  var install_all_button = document.createElement('button');
  install_all_button.setAttribute('style', 'background-color: orange');
  install_all_button.textContent
    = mc('ACCEPT ALL LICENSES AND INSTALL ALL SOFTWARE.');
  install_all_button.addEventListener(
    'click',
    function(e) { e.preventDefault();
                  for (i in install_pkg_functions) {
                    install_pkg_functions[i]();
                  }
                });

  form.appendChild(install_all_button);
  form.appendChild(pkgcontrols_table);
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
        var table = document.createElement('table');
        var tr    = table.appendChild( document.createElement('tr')    );
        var td    = tr   .appendChild( document.createElement('td')    );
        var input = td   .appendChild( document.createElement('input') );
        input.setAttribute('name', fieldname);
        input.setAttribute('type', 'text');
        input.setAttribute('value', value);
        input.addEventListener('focusout', function(e) {
                                             update_listwidgets();
                                             write_config(); });
        input.addEventListener('keyup', function(e) {
                                          update_listwidgets();
                                          write_config(); });

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
  } catch (ex) {
    if (ex.code === 'ENOENT') {
      // default config in case everything is missing
      config = {
        allow_logins_for:   [],
        allow_remoteadmins: false,
        local_users:        {},      // historical leftover
        version:            1,
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
    allow_logins_for:   [],
    allow_remoteadmins: false,
    version:            1,

    // local_users is a historical leftover that should always be empty...
    // I do not want to change the configuration file version only to clean
    // this up.
    local_users: {},
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

  new_config.allow_remoteadmins = response.allow_remoteadmins.checked;

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

generate_form();
