var child_process = require('child_process');
var fs = require('fs');
var gui = require('nw.gui');

var gui_config;

var config_json_dir  = '/state/etc/puavo/local';
var config_json_path = config_json_dir + '/config.json';
var old_config;

var device_json_path = '/state/etc/puavo/device.json';
var device_config;

var locale = process.env.LANG.substring(0, 2);

var mc =
  function(msg) {
    translations = {
      fi: {
        'Laptop configuration': 'Kannettavan asetukset',

        'Additional software installation': 'Lisäohjelmistojen asennus',

        'The following software have licenses that do not allow preinstallation.  You can install them from here, but by installing you accept the software license terms.  Note!  Software installation requires network connection.  Software installation may take several minutes.  Closing the window will interrupt installation.': 'Lisäohjelmistot ovat sovelluksia, joita ei ole lisenssiehtojen vuoksi voitu asentaa kannettavalle valmiiksi.  Voit asentaa tarvitsemiasi ohjelmistoja tästä ja samalla hyväksyt niiden lisenssiehdot.  Huom!  Ohjelmistojen asennus vaatii verkkoyhteyden.  Ohjelmistojen asentaminen voi kestää useita minuutteja.  Ikkunan sulkeminen keskeyttää asennuksen.',

        'ACCEPT ALL LICENSES AND INSTALL ALL SOFTWARE.':
           'HYVÄKSY KAIKKI LISENSSIT JA ASENNA KAIKKI OHJELMAT.',

        'Error in installation, check network.':
           'Asennus ei onnistunut, tarkista verkkoyhteys.',

        'Error in installation, unknown reason.':
           'Asennus ei onnistunut, tuntematon syy.',

        'Access controls': 'Pääsyoikeudet',

        'Configuration needs corrections, no changes are saved.':
          'Asetukset vaativat korjausta, muutokset eivät tallennu.',

        'Local user management': 'Paikallisten käyttäjien hallinta',

        'Add another user': 'Lisää uusi käyttäjä',
        'Local users:':     'Paikalliset käyttäjät:',
        'Login:':           'Käyttäjätunnus:',
        'Name:':            'Nimi:',
        'OK?':              'OK?',
        'Password again:':  'Salasana uudestaan:',
        'Password:':        'Salasana:',
        'remove':           'poista',

        'Login is the same one that primary user has.':
          'Käyttäjätunnus on sama kuin ensisijaisella käyttäjällä.',
        'Login is not in correct format.':
          'Käyttäjätunnus ei ole oikean muotoinen',
        'Name is not in correct format.':
          'Nimi ei ole oikean muotoinen',
        'Passwords do not match.':
          'Salasanat eivät täsmää.',

        'Allow logins for:':        'Salli kirjautumiset käyttäjätunnuksille:',
        'All puavo domain users':   'Kaikki puavo-domain käyttäjät',
        'Some puavo domain users:': 'Jotkut puavo-domain käyttäjät:',

        'Allow login from remote admins:':
          'Salli kirjautumiset etäylläpitäjille:',

        'INSTALL':         'ASENNA',
        'Installing...':   'Asennetaan...',
        'license terms':   'lisenssiehdot',
        'Uninstalling...': 'Poistetaan...',
        'UNINSTALL':       'POISTA',

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

        'Error in installation, check network.':
          'Error in installation, check network.', // XXX

        'Error in installation, unknown reason.':
          'Error in installation, unknown reason.', // XXX

        'Access controls': 'Access controls', // XXX

        'Local user management': 'Local user management', // XXX

        'Configuration needs corrections, no changes are saved.':
          'Inställningarna kräver korrigering, inga ändringar har sparats',

        'Add another user': 'Lägg till en annan användare',
        'Local users:':     'Lokala användarna:',
        'Login:':           'Inloggning:',
        'Name:':            'Namn:',
        'OK?':              'OK?',
        'Password again:':  'Lösenord igen:',
        'Password:':        'Lösenord:',
        'remove':           'ta bort',

        'Login is not in correct format.':
          'Inloggning är inte i rätt format.',
        'Name is not in correct format.':
          'Namnet är inte i rätt format.',
        'Passwords do not match.':
          'Lösenorden stämmer inte.',

        'Allow logins for:':        'Tillåt inloggningar för:',
        'All puavo domain users':   'Alla puavo domänanvändare',
        'Some puavo domain users:': 'Några puavo domänanvändare:',

        'Allow login from remote admins:':
          'Tillåt inloggning för fjärradmins:',

        'INSTALL':         'INSTALLERA',
        'Installing...':   'Installering...',
        'license terms':   'licensvillkor',
        'Uninstalling...': 'Avinstallering...',
        'UNINSTALL':       'AVINSTALLERA',

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
        sorted_pkgnames = Object.keys(packages).sort();
        for (var i in sorted_pkgnames) {
          var pkgname = sorted_pkgnames[i];
          var license_url = packages[pkgname].license_url;
          if (!license_url) {
            alert('Package ' + pkgname + ' is missing license url');
            continue;
          }
          var install_pkg_fn = add_one_pkgcontrol(table,
                                                  pkgname,
                                                  license_url,
                                                  sw_states[pkgname]);
          install_pkg_functions.push(install_pkg_fn);
        }
      };

  check_software_states(add_each_pkgcontrol, Object.keys(packages));

  return install_pkg_functions;
}

function add_one_pkgcontrol(parentNode, pkgname, license_url, sw_state) {
  var tr = document.createElement('tr');

  // create license name element
  var pkgname_td = document.createElement('td');
  pkgname_td.textContent = pkgname;
  tr.appendChild(pkgname_td);

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
  button_and_install_action = add_action_button(pkgname,
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

function configure_system_and_exit() {
  var cmd_args = [ '/usr/sbin/puavo-local-config', '--local-users' ];

  var handler
    = function(error, stdout, stderr) {
        process.exit(error ? 1 : 0);
      };

  child_process.execFile('sudo', cmd_args, {}, handler);
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
    = function(tr, value, text, checked) {
        var input = document.createElement('input');
        if (checked) {
          input.setAttribute('checked', true);
        } else {
          input.removeAttribute('checked');
        }
        input.setAttribute('name', 'allow_logins_for');
        input.setAttribute('type', 'radio');
        input.setAttribute('value', value);
        input.addEventListener('click', write_config);

        var tr = table.appendChild( document.createElement('tr') );
        var td = tr   .appendChild( document.createElement('td') );

        var textnode = document.createTextNode(text);
        td.appendChild(input);
        td.appendChild(textnode);

        return tr;
      };

  var all_is_chosen = (old_config.allow_logins_for.indexOf('*') >= 0);

  make_radiobutton(table,
                   'all_puavo_domain_users',
                   mc('All puavo domain users'),
                   all_is_chosen);

  var rb_tr = make_radiobutton(table,
                               'some_puavo_domain_users',
                               mc('Some puavo domain users:'),
                               !all_is_chosen);

  var nonlocal_users_allowed_logins = [];
  if (!all_is_chosen) {
    for (i in old_config.allow_logins_for) {
      var user = old_config.allow_logins_for[i];
      if (! (old_config.local_users[user]
               && old_config.local_users[user].enabled)) {
        nonlocal_users_allowed_logins.push(user);
      }
    }
  }

  make_listwidgets(rb_tr,
                   'allowed_puavo_users',
                   nonlocal_users_allowed_logins);

  var title = document.createElement('div');
  title.textContent = mc('Allow logins for:');
  title.appendChild(table);

  form.appendChild(title);
}

function generate_allow_remoteadmins_input(form) {
  var div = document.createElement('div');
  var titletext
    = document.createTextNode( mc('Allow login from remote admins:') );
  div.appendChild(titletext);

  var input = document.createElement('input');
  input.setAttribute('name', 'allow_remoteadmins');
  input.setAttribute('type', 'checkbox');
  if (old_config.allow_remoteadmins) {
    input.setAttribute('checked', true);
  } else {
    input.removeAttribute('checked');
  }
  input.addEventListener('click', write_config);

  div.appendChild(input);
  form.appendChild(div);
}

function generate_form(gui_config) {
  var form = document.querySelector('form[id=dynamic_form]');

  // software installation
  if (gui_config.show_puavopkg_controls) {
    generate_software_installation_controls(form);
  }

  // login-access control
  generate_loginaccess_control(form);

  // managing local users
  if (gui_config.show_local_users) {
    generate_login_users_input(form);
  }
}

function generate_loginaccess_control(form) {
  var title = document.createElement('h2');
  title.textContent = mc('Access controls');
  form.appendChild(title);

  generate_allow_logins_input(form);
  generate_allow_remoteadmins_input(form);
}

function generate_login_users_input(form) {
  var title = document.createElement('h2');
  var titletext = document.createTextNode( mc('Local user management') );
  title.appendChild(titletext);

  form.appendChild(title);

  var subtitle = document.createElement('div');
  var subtitletext = document.createTextNode( mc('Local users:') );
  subtitle.appendChild(subtitletext);

  var add_button = document.createElement('input');
  add_button.setAttribute('type', 'button');
  add_button.setAttribute('value', mc('Add another user'));
  subtitle.appendChild(add_button);

  form.appendChild(subtitle);

  var user_inputs = document.createElement('div');
  form.appendChild(user_inputs);

  var local_users_list = [];
  for (login in old_config.local_users) {
    if (old_config.local_users[login].enabled) {
      local_users_list.push({
                              login: login,
                              name:  old_config.local_users[login].name,
                            });
    }
  }

  var append_empty_user
    = function() { 
        local_users_list.push({ hashed_password: '!',
                                login:           '',
                                name:            '', }); }

  // create at least one empty user
  if (local_users_list.length === 0) { append_empty_user(); }

  for (i in local_users_list)
    generate_one_user_create_table(user_inputs, local_users_list, i);
 
  var add_new_user
    = function(e) {
        e.preventDefault();
        append_empty_user();
        var last_i = local_users_list.length - 1;
        generate_one_user_create_table(user_inputs, local_users_list, last_i);
      };

  add_button.addEventListener('click', add_new_user);
}

function generate_one_user_create_table(parentNode, local_users_list, user_i) {
  var user_div = document.createElement('div');
  parentNode.appendChild(user_div);

  var table = document.createElement('table');

  var old_user_data = local_users_list[user_i];
  var login = old_user_data.login;

  var fields = [
    {
      name:     mc('Login:'),
      key:      'login',
      type:     'text',
      value_fn: function(input) { input.setAttribute('value', login) },
    },
    {
      name:     mc('Name:'),
      key:      'name',
      type:     'text',
      value_fn: function(input) {
                  input.setAttribute('value', old_user_data.name) },
    },
    {
      name: mc('Password:'),
      key:  'password1',
      type: 'password',
    },
    {
      name: mc('Password again:'),
      key:  'password2',
      type: 'password',
    },
  ];

  var make_input
    = function(fieldinfo) {
        input = document.createElement('input');
        input.setAttribute('name',
                           'localuser_' + user_i + '_' + fieldinfo.key);
        input.setAttribute('type', fieldinfo.type);
        if (fieldinfo.value_fn) { fieldinfo.value_fn(input); }
        input.addEventListener('keyup', write_config);
        input.addEventListener('focusout', write_config);
        return input;
      };

  fields.forEach(function (fieldinfo) { 
                   var tr = document.createElement('tr');

                   var name_td = document.createElement('td');
                   name_td.textContent = fieldinfo.name;
                   tr.appendChild(name_td);

                   var input_td = document.createElement('td');

                   var input;
                   if (fieldinfo.key === 'login' && login !== '') {
                     input_td.appendChild( document.createTextNode(login) );
                     input = make_input({
                               key: 'login',
                               type: 'hidden',
                               value_fn: function(i) {
                                 i.setAttribute('value', login) }
                             });
                   } else {
                     input = make_input(fieldinfo);
                   }

                   input_td.appendChild(input);
                   tr.appendChild(input_td);

                   if (fieldinfo.key === 'login') {
                     var delete_create_user_table
                       = function(e) {
                           e.preventDefault();
                           var ok = (old_user_data.login === '')
                                      || confirm( mc('OK?') );
                           if (ok) { parentNode.removeChild(user_div); }
                           write_config();
                         };

                     var remove_td = document.createElement('td');
                     var input = document.createElement('input');
                     input.setAttribute('type', 'button');
                     input.setAttribute('value', mc('remove'));
                     input.addEventListener('click', delete_create_user_table);
                     remove_td.appendChild(input);
                     tr.appendChild(remove_td);
                   } else {
                     tr.appendChild( document.createElement('td') );
                   }

		   var error_td = document.createElement('td');
		   error_td.setAttribute('class', 'error');
		   error_td.setAttribute('id',
					 'localuser_'
					   + user_i
					   + '_error_'
					   + fieldinfo.key);
		   tr.appendChild(error_td);

                   table.appendChild(tr);
                 });

  user_div.appendChild(table);
  user_div.appendChild( document.createElement('hr') );
}

function generate_software_installation_controls(form) {
  var packages = get_packages();
  if (Object.keys(packages).length === 0) { return; }

  var title = document.createElement('h2');
  title.textContent = mc('Additional software installation');
  form.appendChild(title);

  var textdiv = document.createElement('div');
  textdiv.textContent = mc('The following software have licenses that do not allow preinstallation.  You can install them from here, but by installing you accept the software license terms.  Note!  Software installation requires network connection.  Software installation may take several minutes.  Closing the window will interrupt installation.');
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

function hash_password(password, cb) {
  // if user did not provide a password,
  // use the password from old configuration
  if (password === '') { return cb(''); }

  var handler
    = function (error, stdout, stderr) {
        if (error) { throw(error); }
        cb(stdout.toString().replace(/\n$/, ''));
      };

  var child = child_process.execFile('mkpasswd',
                                     [ '-m', 'sha-512', '-s' ],
                                     {},
                                     handler);

  child.stdin.end(password);
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

function make_local_users_config(response,
                                 user_indexes,
                                 new_config,
                                 has_errors,
                                 cb) {
  if (user_indexes.length === 0)
    return cb(has_errors);

  var i = user_indexes.pop();

  var login     = response['localuser_' + i + '_login'    ].value;
  var name      = response['localuser_' + i + '_name'     ].value;
  var password1 = response['localuser_' + i + '_password1'].value;
  var password2 = response['localuser_' + i + '_password2'].value;

  var errors = {
    login: document.querySelector('td[id=localuser_' + i + '_error_login]'),
    name:  document.querySelector('td[id=localuser_' + i + '_error_name]'),
    password1:
      document.querySelector('td[id=localuser_' + i + '_error_password1]'),
  };

  for (i in errors)
    errors[i].innerText = '';

  var next_user_fn = function() {
                       make_local_users_config(response,
                                               user_indexes,
                                               new_config,
                                               has_errors,
                                               cb);
                     };

  if (login.match(/^\s*$/) && name.match(/^\s*$/))
    return next_user_fn();

  if (device_config.primary_user === login) {
    errors.login.innerText = mc('Login is the same one that primary user has.');
    has_errors = true;
  } else if (!login.match(/^[a-z\.-]+$/)) {
    errors.login.innerText = mc('Login is not in correct format.');
    has_errors = true;
  }

  if (!name.match(/^[a-zA-Z\. -]+$/)) {
    errors.name.innerText = mc('Name is not in correct format.');
    has_errors = true;
  }

  if (password1 !== password2) {
    errors.password1.innerText = mc('Passwords do not match.');
    has_errors = true;
  }

  user = new_config.local_users[login];

  var uid;
  if (user && user.uid) {
    uid = user.uid;
  } else {
    var uids = Object.keys(new_config.local_users)
                     .map(function(key) {
                            return new_config.local_users[key].uid; });
    var max_fn = function(a,b) { return Math.max(a,b); };

    uid = uids.reduce(max_fn, 3000) + 1;
  }

  hash_password(password1,
                function(hp) {
                  var pw = hp || (user && user.hashed_password) || '!';

                  new_config.local_users[login] = {
                    enabled:         true,
                    hashed_password: pw,
                    name:            name,
                    uid:             uid,
                  };

                  next_user_fn();
               });
}

function open_external_link(e) {
  var child = child_process.spawn('chromium-browser',
                                  [ '--app=' + e.href,
                                    '--window-position=480,60',
                                    '--window-size=640,580' ],
                                  { detached: true, stdio: 'ignore' });
  child.unref();
}

function parse_gui_config() {
  gui_config_path = '/etc/puavo-local-config/puavo-local-config-ui.conf';

  gui_config = { show_local_users: true, show_puavopkg_controls: true };
  config_in_file = JSON.parse( fs.readFileSync(gui_config_path) );
  for (var attr in config_in_file) {
    gui_config[attr] = config_in_file[attr];
  }

  return gui_config;
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
        local_users:        {},
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

function read_device_config() {
  try {
    return JSON.parse( fs.readFileSync(device_json_path) );
  } catch (ex) {
    return {};
  }
}

function write_config() {
  var response = document.forms[0].elements;
  var new_config = {
    allow_logins_for:   [],
    allow_remoteadmins: false,
    version:            1,
  };

  // Initialize new_config.local_users with old information,
  // but disable all users (those will be enabled later, if given in user
  // interface).
  new_config.local_users = {};
  for (user in old_config.local_users) {
    var old = old_config.local_users[user];
    new_config.local_users[user] = {
                                     enabled:         false,
                                     hashed_password: old.hashed_password,
                                     name:            old.name,
                                     uid:             old.uid,
                                   };
  }

  var do_after_local_users_are_ok =
    function(has_errors) {
      document.querySelector('div[id=error_banner]').innerText
        = has_errors
            ? mc('Configuration needs corrections, no changes are saved.')
            : '';

      // make sure that disabled users have password '!'
      for (user in new_config.local_users) {
        if (new_config.local_users[user].enabled) {
          new_config.allow_logins_for.push(user);
        } else {
          new_config.local_users[user].hashed_password = '!';
        }
      }

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
    };

  var user_indexes = [];
  for (i in response) {
    match = response[i].name
              && response[i].name.match(/^localuser_(\d+)_login$/);
    if (match) { user_indexes.push(match[1]); }
  }

  make_local_users_config(response,
                          user_indexes,
                          new_config,
                          false,
                          do_after_local_users_are_ok);
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

gui_config = parse_gui_config();

old_config = read_config();
if (!old_config) { process.exit(1); }

device_config = read_device_config();

// set document titles
document.querySelector('title').innerText = mc('Laptop configuration');
document.querySelector('h1'   ).innerText = mc('Laptop configuration');

generate_form(gui_config);

gui.Window.get().on('close', configure_system_and_exit);

var all_signals = [ 'SIGHUP'
                  , 'SIGINT'
                  , 'SIGQUIT'
                  , 'SIGILL'
                  , 'SIGABRT'
                  , 'SIGFPE'
                  , 'SIGSEGV'
                  , 'SIGPIPE'
                  , 'SIGALRM'
                  , 'SIGTERM'
                  , 'SIGUSR1'
                  , 'SIGUSR2'
                  , 'SIGTSTP'
                  , 'SIGTTIN'
                  , 'SIGTTOU' ];

// XXX does not always run code in configure_system_and_exit :-(
all_signals
  .forEach(function(eventname) {
             process.on(eventname, configure_system_and_exit);
           });
