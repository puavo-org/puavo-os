var child_process = require('child_process');
var fs = require('fs');

var config_json_path = '/state/etc/puavo/local/config.json';
var old_config;

function add_action_button(license_key,
                           errormsg_element,
                           sw_state,
                           user_wants_it) {
  var button = document.createElement('button');

  installation = user_wants_it ? 'installing' : 'press_install';

  button_state
    = {
        DOWNLOADED: installation,
        PURGED:     installation,
        INSTALLED:  'press_uninstall',
      }[sw_state] || installation;

  create_action_button_with_initial_state(button,
                                          button_state,
                                          license_key,
                                          errormsg_element);

  return button;
}

function add_licenses(table, license_list) {
  check_software_state(function (sw_state) {
                         for (var i in license_list) {
                           var license = license_list[i];
                           add_one_license(table,
                                           license,
                                           sw_state[license.key],
                                           old_config.licenses[license.key]);
                         }
                       });
}

function add_one_license(parentNode, license_info, sw_state, user_wants_it) {
  var tr = document.createElement('tr');

  // create license name element
  var license_name_td = document.createElement('td');
  license_name_td.textContent = license_info.name;
  tr.appendChild(license_name_td);

  // create license url link
  var license_url_td = document.createElement('td');
  var a = document.createElement('a');
  a.setAttribute('href', license_info.url);
  a.addEventListener('click',
                     function(e) { e.preventDefault();
                                   open_external_link(a); });
  a.textContent = '(license terms)';
  tr.appendChild( license_url_td.appendChild(a) );

  // create action button and error element
  var action_td = document.createElement('td');
  var action_errormsg_element = document.createElement('td');
  action_td.appendChild( add_action_button(license_info.key,
                                           action_errormsg_element,
                                           sw_state,
                                           user_wants_it) );
  tr.appendChild(action_td);
  tr.appendChild(action_errormsg_element);

  parentNode.appendChild(tr);
}

function check_software_state(cb) {
  var handler
    = function (error, stdout, stderr) {
        if (error) { throw(error); }

        sw_state = {};
        stdout.toString()
              .split("\n")
              .forEach(function (line) {
                         if (line !== '') {
                           a = line.split(/\s+/);
                           sw_state[ a[0] ] = a[2];
                         }
                       });
        cb(sw_state);
      };

  child_process.execFile('puavo-restricted-package-tool',
                         [ 'list' ],
                         {},
                         handler);
}

function configure_system() {
  var cmd_args = [ '/usr/sbin/puavo-local-config'
                 , '--local-users'
                 , '--setup-pkgs', 'all' ];

  var handler
    = function(error, stdout, stderr) {
        if (error) {
          throw(error);
          /* XXX how to handle this properly? */
        }
      };

  child_process.execFile('sudo', cmd_args, {}, handler);
}

function create_action_button_with_initial_state(button,
                                                 initial_state,
                                                 license_key,
                                                 errormsg_element) {
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

  var state_functions = {
    installing:
      function() {
        button.textContent = 'Installing...';
        button.setAttribute('style', styles.installing_a);
        flash_interval
          = setInterval(function () { make_flashes('installing_a',
                                                   'installing_b'); },
                        500);
      },
    press_install:
      function() {
        button.textContent = 'INSTALL';
        button.setAttribute('style', styles.install);
        setup_action(function(e) {
                       e.preventDefault();
                       handle_pkg('install',
                                  license_key,
                                  errormsg_element,
                                  install_returned);
                       state_functions.installing();
                     });
      },
    press_uninstall:
      function() {
        button.textContent = 'UNINSTALL';
        button.setAttribute('style', styles.uninstall);
        setup_action(function(e) {
                       e.preventDefault();
                       handle_pkg('uninstall',
                                  license_key,
                                  errormsg_element,
                                  uninstall_returned);
                       state_functions.uninstalling();
                     });
      },
    uninstalling:
      function() {
        button.textContent = 'Uninstalling...';
        button.setAttribute('style', styles.uninstalling_a);
        flash_interval
          = setInterval(function () { make_flashes('uninstalling_a',
                                                   'uninstalling_b'); },
                        200);
      },
  };

  state_functions[initial_state]();
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
                   'All puavo domain users',
                   all_is_chosen);

  var rb_tr = make_radiobutton(table,
                               'some_puavo_domain_users',
                               'Some puavo domain users:',
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
  title.textContent = 'Allow logins for:';
  title.appendChild(table);

  form.appendChild(title);

  form.appendChild( document.createElement('hr') );
}

function generate_allow_remoteadmins_input(form) {
  var div = document.createElement('div');
  var titletext = document.createTextNode('Allow login from remote admins:');
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

  form.appendChild( document.createElement('hr') );
}

function generate_form() {
  var form = document.querySelector('form[id=dynamic_form]');

  generate_login_users_input(form);
  generate_allow_logins_input(form);
  generate_allow_remoteadmins_input(form);
  generate_software_installation_controls(form);
}

function generate_login_users_input(form) {
  var title = document.createElement('div');
  var titletext = document.createTextNode('Local users:');
  title.appendChild(titletext);

  var add_button = document.createElement('input');
  add_button.setAttribute('type', 'button');
  add_button.setAttribute('value', 'Add another user');
  title.appendChild(add_button);

  form.appendChild(title);

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

  form.appendChild( document.createElement('hr') );
}

function generate_one_user_create_table(parentNode, local_users_list, user_i) {
  var user_div = document.createElement('div');
  parentNode.appendChild(user_div);

  var div = document.createElement('div');
  div.setAttribute('id', 'localuser_' + user_i + '_errors');
  user_div.appendChild(div);

  var table = document.createElement('table');

  var old_user_data = local_users_list[user_i];
  var login = old_user_data.login;
  
  var fields = [
    {
      name:     'Login:',
      key:      'login',
      type:     'text',
      value_fn: function(input) { input.setAttribute('value', login) },
    },
    {
      name:     'Name:',
      key:      'name',
      type:     'text',
      value_fn: function(input) {
                  input.setAttribute('value', old_user_data.name) },
    },
    {
      name: 'Password:',
      key:  'password1',
      type: 'password',
    },
    {
      name: 'Password again:',
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
                                      || confirm('OK?');
                           if (ok) { parentNode.removeChild(user_div); }
                           write_config();
                         };

                     var remove_td = document.createElement('td');
                     var input = document.createElement('input');
                     input.setAttribute('type', 'button');
                     input.setAttribute('value', 'remove');
                     input.addEventListener('click', delete_create_user_table);
                     remove_td.appendChild(input);
                     tr.appendChild(remove_td);
                   }

                   table.appendChild(tr);
                 });

  user_div.appendChild(table);
  user_div.appendChild( document.createElement('hr') );
}

function generate_software_installation_controls(form) {
  var table = document.createElement('table');

  add_licenses(table, get_license_list());

  form.appendChild(table);
}

function get_license_list() {
  var basedir = '/usr/share/puavo-ltsp-client/restricted-packages';
  try {
    var software_directories = fs.readdirSync(basedir);
  } catch (ex) {
    alert(ex);
    return [];
  };

  var list = [];

  for (var i in software_directories) {
    var dir = software_directories[i];
    var dir_fullpath = basedir + '/' + dir;
    if (! fs.statSync(dir_fullpath).isDirectory())
      continue;

    var license_path = dir_fullpath + '/license.json';
    try {
      var license_info = JSON.parse(fs.readFileSync(license_path));
    } catch(ex) { alert(ex); continue; }

    if (license_info && license_info.name && license_info.url) {
      license_info.key = dir;
      list.push(license_info);
    } else {
      alert('License information was not in correct format in '
              + license_path);
    }
  }

  return list;
}

function handle_pkg(mode, license_key, errormsg_element, cb) {
  cmd_mode = (mode === 'install' ? '--install-pkgs' : '--uninstall-pkgs');
  var cmd_args = [ '/usr/sbin/puavo-local-config', cmd_mode, license_key ]

  var handler
    = function(error, stdout, stderr) {
        errormsg_element.textContent = error ? stderr : '';
        cb(error);
      };

  child_process.execFile('sudo', cmd_args, {}, handler);
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

  var error_element
    = document.querySelector('div[id=localuser_' + i + '_errors]');

  var errors = [];
  var update_errormsg = function() {
                          error_element.textContent = errors.join(' / '); };

  var next_user_fn = function() {
                       update_errormsg();
                       make_local_users_config(response,
                                               user_indexes,
                                               new_config,
                                               has_errors,
                                               cb);
                     };

  if (login.match(/^\s*$/) && name.match(/^\s*$/))
    return next_user_fn();

  if (!login.match(/^[a-z\.-]+$/))
    errors.push('Login is not in correct format.');

  if (!name.match(/^[a-zA-Z\. -]+$/))
    errors.push('Name is not in correct format.');

  if (password1 !== password2)
    errors.push('Passwords do not match.');

  update_errormsg();
  if (errors.length > 0)
    has_errors = true;

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
  var child = child_process.spawn('x-www-browser',
                                  [ e.href ],
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
        allow_logins_for:   [ '*' ],
        allow_remoteadmins: false,
        licenses:           {},
        local_users:        {},
      };
    } else {
      alert(ex);
      return false;
    }
  }

  return config;
}

function write_and_apply_config(conf) {
  try {
    var data = JSON.stringify(conf) + "\n";
    var tmpfile = config_json_path + '.tmp';
    fs.writeFileSync(tmpfile, data);
    fs.renameSync(tmpfile, config_json_path);
  } catch (ex) { alert(ex); throw(ex); }

  // XXX when should this be done?
  // configure_system();
}

function write_config() {
  var response = document.forms[0].elements;
  var new_config = {
    allow_logins_for:   [],
    allow_remoteadmins: false,
    licenses:           {},
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
      /* XXX this should update a big banner that no configuration updated
       * XXX because of errors */
      if (has_errors) { return; }

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

      for (i in response) {
        if (response[i].className === 'license_acceptance_checkbox') {
          var name = response[i].getAttribute('name');
          new_config.licenses[name] = response[i].checked;
        }
      }

      write_and_apply_config(new_config);
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

old_config = read_config();
if (!old_config) { process.exit(1); }

generate_form();
