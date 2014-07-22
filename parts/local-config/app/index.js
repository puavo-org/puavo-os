var child_process = require('child_process');
var fs = require('fs');

var config_json_path = '/state/etc/puavo/local/config.json';

function add_download_button(license_key, errormsg_element, download_done) {
  var button = document.createElement('button');

  var styles = {
    error:      'background-color: red',
    ok:         'background-color: lightgreen',
    download_a: 'background-color: yellow',
    download_b: 'background-color: white',
  };

  if (download_done) {
    button.textContent = 'INSTALLED';
    button.setAttribute('style', styles.ok);
    return button;
  }

  button.textContent = 'DOWNLOAD';
  button.addEventListener('click',
                          function(e) {
                            e.preventDefault();
                            download_pkg(license_key,
                                         button,
                                         styles,
                                         errormsg_element); });

  return button;
}

function add_licenses(table, old_config, license_list) {
  check_download_packs(function (downloaded_packs) {
                         for (var i in license_list) {
                           var license = license_list[i];
                           add_one_license(table,
                                           license,
                                           downloaded_packs[license.key],
                                           old_config.licenses[license.key]);
                         }
                       });
}

function add_one_license(parentNode, license_info, download_done, checked) {
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

  var download_td = document.createElement('td');
  var download_errormsg_element = document.createElement('td');
  download_td.appendChild( add_download_button(license_info.key,
                                               download_errormsg_element,
                                               download_done) );
  tr.appendChild(download_td);

  var accept_td = document.createElement('td');
  var input = document.createElement('input');
  input.setAttribute('class', 'license_acceptance_checkbox');
  input.setAttribute('name', license_info.key);
  input.setAttribute('type', 'checkbox');
  if (checked) {
    input.setAttribute('checked', true);
  } else {
    input.removeAttribute('checked');
  }

  tr.appendChild( accept_td.appendChild(input) );

  tr.appendChild(download_errormsg_element);

  parentNode.appendChild(tr);
}

function make_local_users_config(response,
                                 user_indexes,
                                 old_config,
                                 new_config,
                                 has_errors,
                                 cb) {
  if (user_indexes.length === 0)
    return cb(has_errors);

  var i = user_indexes.pop();

  var next_user_fn = function() {
                       make_local_users_config(response,
                                               user_indexes,
                                               old_config,
                                               new_config,
                                               has_errors,
                                               cb);
                     };

  var login     = response['localuser_' + i + '_login'    ].value;
  var name      = response['localuser_' + i + '_name'     ].value;
  var is_admin  = response['localuser_' + i + '_admin'    ].checked;
  var password1 = response['localuser_' + i + '_password1'].value;
  var password2 = response['localuser_' + i + '_password2'].value;

  var error_element
    = document.querySelector('div[id=localuser_' + i + '_errors]');

  var errors = [];

  if (login.match(/^\s*$/) && name.match(/^\s*$/))
    next_user_fn();

  if (!login.match(/^[a-z\.-]+$/))
    errors.push('Login is not in correct format.');

  if (!name.match(/^[a-zA-Z\. -]+$/))
    errors.push('Name is not in correct format.');

  if (password1 !== password2)
    errors.push('Passwords do not match.');

  if (errors.length > 0) {
    error_element.textContent = errors.join(' / ');
    has_errors = true;
  }

  if (is_admin)
    new_config.admins.push(login);

  new_config.allow_logins_for.push(login);

  old_user = old_config.local_users[login];

  var uid;
  if (old_user && old_user.uid) {
    uid = old_user.uid;
  } else {
    var get_uids = function(conf) {
                     conf ? Object.keys(conf.local_users)
                                  .map(function(key) {
                                         return conf.local_users[key].uid; })
                          : []
                   };
    var max_fn = function(a,b) { return Math.max(a,b); };

    old_uids = get_uids(old_config);
    new_uids = get_uids(new_config);

    debugger; /* XXX this does not work yet, properly */
    uid = old_uids.concat(new_uids).reduce(max_fn, 3000) + 1;
  }

  hash_password(password1,
                function(hp) {
                  var pw = hp || (old_user && old_user.hashed_password) || '!';

                  new_config.local_users[login] = {
                    hashed_password: pw,
                    name:            name,
                    uid:             uid,
                  };

                  next_user_fn();
               });
}

function assemble_config_and_exit(old_config) {
  var response = document.forms[0].elements;
  var new_config = {
    admins:             [],
    allow_logins_for:   [],
    allow_remoteadmins: false,
    licenses:           {},
    local_users:        {},
    version:            1,
  };

  var do_after_local_users_are_ok =
    function(has_errors) {
      if (has_errors) { return; }

      switch(response.allow_logins_for.value) {
        case 'all_puavo_domain_users':
          new_config.allow_logins_for = [ '*' ];
          break;
        case 'some_puavo_domain_users':
          var allowed_puavo_users = [];
          for (i in response.allowed_puavo_users) {
            var user = response.allowed_puavo_users[i].value;
            if (user && user.match(/\S+/)) { allowed_puavo_users.push(user); }
          }

          new_config.allow_logins_for
            = allowed_puavo_users.concat(Object.keys(new_config.local_users));

          break;
      }

      new_config.allow_remoteadmins = response.allow_remoteadmins.checked;

      for (i in response) {
        if (response[i].className === 'license_acceptance_checkbox') {
          var name = response[i].getAttribute('name');
          new_config.licenses[name] = response[i].checked;
        }
      }

      write_config_json_and_exit(new_config);
    };

  var user_indexes = [];
  for (i in response) {
    match = response[i].name
              && response[i].name.match(/^localuser_(\d+)_login$/);
    if (match) { user_indexes.push(match[1]); }
  }

  make_local_users_config(response,
                          user_indexes,
                          old_config,
                          new_config,
                          false,
                          do_after_local_users_are_ok);
}

function check_download_packs(cb) {
  var handler
    = function (error, stdout, stderr) {
        if (error) { throw(error); }

        obj = {};
        stdout.toString()
              .split("\n")
              .forEach(function (line) {
                         if (line !== '') {
                           a = line.split(/\s+/);
                           obj[ a[0] ] = (a[2] !== 'PURGED');
                         }
                       });
        cb(obj);
      };

  child_process.execFile('puavo-restricted-package-tool',
                         [ 'list' ],
                         {},
                         handler);
}

function configure_system_and_exit() {
  process.exit(0);

  var cmd_args = [ '/usr/sbin/puavo-local-config'
                 , '--admins'
                 , '--local-users'
                 , '--setup-pkgs', 'all' ];

  var handler
    = function(error, stdout, stderr) {
        if (error) { throw(error); }
        process.exit(0);
      };

  child_process.execFile('sudo', cmd_args, {}, handler);
}

function diff_arrays(a, b) {
  return a.filter(function(i) { return b.indexOf(i) < 0; });
};

function download_pkg(license_key, button, styles, error_element) {
  button.textContent = 'Downloading...';
  button.setAttribute('style', styles.download_a);

  var flashes
    = function() {
        if (button.getAttribute('style') === styles.download_a) {
          button.setAttribute('style', styles.download_b);
        } else if (button.getAttribute('style') == styles.download_b) {
          button.setAttribute('style', styles.download_a);
        }
      };

  var flash_interval = setInterval(flashes, 500);

  var cmd_args = [ '/usr/sbin/puavo-local-config'
                 , '--download-pkgs'
                 , license_key ]

  var handler
    = function(error, stdout, stderr) {
        if (error) {
          button.setAttribute('style', styles.error);
          button.textContent = 'ERROR';
          error_element.textContent = stderr;
        } else {
          button.setAttribute('style', styles.ok);
          button.textContent = 'INSTALLED';
          error_element.textContent = '';
        }
        clearInterval(flash_interval);
      };

  child_process.execFile('sudo', cmd_args, {}, handler);
}

function generate_allow_logins_input(form, old_config) {
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
    nonlocal_users_allowed_logins
      = diff_arrays(old_config.allow_logins_for,
                    Object.keys(old_config.local_users));
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

function generate_allow_remoteadmins_input(form, old_config) {
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

  div.appendChild(input);
  form.appendChild(div);

  form.appendChild( document.createElement('hr') );
}

function generate_software_installation_controls(form, old_config) {
  var table = document.createElement('table');

  add_licenses(table, old_config, get_license_list());

  form.appendChild(table);
}

function generate_form(old_config) {
  var form = document.querySelector('form[id=dynamic_form]');

  generate_login_users_input(form, old_config);
  generate_allow_logins_input(form, old_config);
  generate_allow_remoteadmins_input(form, old_config);
  generate_software_installation_controls(form, old_config);
  generate_done_button(form, old_config);
}

function generate_login_users_input(form, old_config) {
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
  for (login in old_config.local_users)
    local_users_list.push({
                            is_admin: (old_config.admins.indexOf(login) >= 0),
                            login:    login,
                            name:     old_config.local_users[login].name,
                          });

  var append_empty_user
    = function() { 
        local_users_list.push({ hashed_password: '', login: '', name: '', }); }

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
      name:     'Has administrative rights:',
      key:      'admin',
      type:     'checkbox',
      value_fn: function(input) {
                  if (old_user_data.is_admin) {
                    input.setAttribute('checked', true);
                  } else {
                    input.removeAttribute('checked');
                  }
                },
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

function generate_done_button(form, old_config) {
  var input = document.createElement('input');
  input.setAttribute('type',  'button');
  input.setAttribute('value', 'Done!');

  input.addEventListener('click',
                         function() { assemble_config_and_exit(old_config) });

  form.appendChild(input);
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
        input.addEventListener('focusout',
                               function(ev) { update_listwidgets(); });
        input.addEventListener('keyup',
                               function(ev) { update_listwidgets(); });

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
        admins:             [],
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

function write_config_json_and_exit(conf) {
  try {
    var data = JSON.stringify(conf) + "\n";
    var tmpfile = config_json_path + '.tmp';
    fs.writeFileSync(tmpfile, data);
    fs.renameSync(tmpfile, config_json_path);
  } catch (ex) { alert(ex); throw(ex); }

  configure_system_and_exit();
}


var old_config = read_config();
if (!old_config) { process.exit(1); }

generate_form(old_config);
