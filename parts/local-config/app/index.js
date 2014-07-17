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

function add_licenses(license_list) {
  var ll = document.querySelector('table[id=license_list]');

  check_download_packs(function (downloaded_packs) {
                         for (var i in license_list) {
                           var license = license_list[i];
                           add_one_license(ll,
                                           license,
                                           downloaded_packs[license.key]);
                         }
                       });
}

function add_one_license(parentNode, license_info, download_done) {
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

  debugger;
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
  tr.appendChild( accept_td.appendChild(input) );

  tr.appendChild(download_errormsg_element);

  parentNode.appendChild(tr);
}

function assemble_config_and_exit(old_config) {
  var response = document.forms[0].elements;
  var new_config = {};

  new_config.allow_logins_for
    = response.allow_logins_for.value === 'all_puavo_domain_users'
        ? [ '*' ]
        : [];

  new_config.licenses = {};
  var license_checkboxes
    = document.querySelectorAll('input[class=license_acceptance_checkbox]');
  [].forEach.call(license_checkboxes,
                  function(lc) {
                    var name = lc.getAttribute('name');
                    new_config.licenses[name] = response[name].checked; });

  new_config.admins
    = response['localuser_0_admin_rights'].checked
        ? [ response['localuser_0_login'].value ]
        : [];

  var local_user_errors = document.querySelector('div[id=localuser_0_errors]');
  local_user_errors.innerHTML = '';
  if (response.localuser_0_password.value
        !== response.localuser_0_password_again.value) {
    local_user_errors.innerHTML = 'Passwords do not match.';
    return;
  }

  new_config.local_users = [
    {
      login: response['localuser_0_login'].value,
      name:  response['localuser_0_name' ].value,
    }
  ];

  // XXX should validate more properly
  if (new_config.local_users[0].login === '') {
    alert('Login is missing');
    return;
  }

  // XXX should validate more properly
  if (new_config.local_users[0].name === '') {
    alert('Name is missing');
    return;
  }

  hash_password(response['localuser_0_password'].value,
                old_config.local_users[0].hashed_password,
                function(hp) {
                  new_config.local_users[0].hashed_password = hp;
                  write_config_json_and_exit(new_config); });
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
          error_element.textContent = stderr;
        } else {
          button.setAttribute('style', styles.ok);
          error_element.textContent = '';
        }
        clearInterval(flash_interval);
      };

  child_process.execFile('sudo', cmd_args, {}, handler);
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

function hash_password(password, old_hashed_password, cb) {
  // if user did not provide a password,
  // use the password from old configuration
  if (password === '') { return cb(old_hashed_password); }

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
    if (ex.code !== 'ENOENT') {
      alert(ex);
      return false;
    } else {
      config = {
        admins:           [],
        allow_logins_for: [ '*' ],
        licenses:         {},
        local_users:      [ { hashed_password: '', login: '', name: '', } ],
      };
    }
  }

  return config;
}

function set_form_values_from_config(config) {
  // allow_logins_for
  allow_logins_for
    = config.allow_logins_for.indexOf('*') >= 0
        ? 'all_puavo_domain_users'
        : 'some_puavo_domain_users';

  [].forEach.call(document.querySelectorAll('input[name=allow_logins_for]'),
                  function(e) {
                    if (e.getAttribute('value') === allow_logins_for)
                      e.setAttribute('checked', true); });

  // local_users
  for (var i in config.local_users) {
    var login = config.local_users[i].login;
    var name  = config.local_users[i].name;

    document.querySelector('input[name=localuser_' + i + '_login')
            .setAttribute('value', login);
    document.querySelector('input[name=localuser_' + i + '_name')
            .setAttribute('value', name);

    // check if user if found in the admins array
    if (config.admins.indexOf(login) >= 0) {
      document.querySelector('input[name=localuser_' + i + '_admin_rights')
              .setAttribute('checked', true);
    } else {
      document.querySelector('input[name=localuser_' + i + '_admin_rights')
              .removeAttribute('checked');
    }
  }

  // licenses
  var license_checkboxes
    = document.querySelectorAll('input[class=license_acceptance_checkbox]');
  [].forEach.call(license_checkboxes,
                  function(lc) {
                    var name = lc.getAttribute('name');
                    if (name in config.licenses && config.licenses[name]) {
                      lc.setAttribute('checked', true);
                    } else {
                      lc.removeAttribute('checked');
                    }
                  });
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

add_licenses(get_license_list());

set_form_values_from_config(old_config);

// in the end print configuration data as json
document.querySelector('input[id=done_button]')
        .addEventListener('click',
                          function() { assemble_config_and_exit(old_config) });
