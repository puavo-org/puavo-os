var child_process = require('child_process');
var fs = require('fs');

var config_json_path = '/state/etc/puavo/local.json';

function done(e) {
  var response = document.forms[0].elements;
  var conf = {};

  conf.allow_login = response.allow_login.value;

  conf.licenses = {};
  var license_checkboxes
    = document.querySelectorAll('input[class=license_acceptance_checkbox]');
  [].forEach.call(license_checkboxes,
                  function(lc) {
                    var name = lc.getAttribute('name');
                    conf.licenses[name] = response[name].checked; });

  var local_user_errors = document.querySelector('div[id=localuser_errors]');
  local_user_errors.innerHTML = '';
  if (response.localuser_password.value
        !== response.localuser_password_again.value) {
    local_user_errors.innerHTML = 'Passwords do not match.';
    return;
  }

  conf.local_user = {
    admin_rights: response.localuser_admin_rights.checked,
    name:         response.localuser_name.value,
    password:     response.localuser_password.value,
  };

  conf.superlaptop_mode = response.superlaptop_mode.checked;

  try {
    fs.writeFileSync(config_json_path,
                     JSON.stringify(conf) + "\n");
  } catch (ex) { alert(ex); throw(ex); }

  process.exit(0);
}

function add_one_license(parentNode, license_info) {
  var tr = document.createElement('tr');

  // create checkbox element
  var td = document.createElement('td');
  var input = document.createElement('input');
  input.setAttribute('class', 'license_acceptance_checkbox');
  input.setAttribute('name', license_info.key);
  input.setAttribute('type', 'checkbox');
  tr.appendChild( td.appendChild(input) );

  // create license name element
  var td = document.createElement('td');
  td.textContent = license_info.name;
  tr.appendChild(td);

  // create license url link
  var td = document.createElement('td');
  var a = document.createElement('a');
  a.setAttribute('href', license_info.url);
  a.addEventListener('click',
                     function(e) { e.preventDefault();
                                   open_external_link(a); });
  a.textContent = '(license terms)';
  tr.appendChild( td.appendChild(a) );

  parentNode.appendChild(tr);
}

function add_licenses(license_list) {
  var ll = document.querySelector('table[id=license_list]');

  for (var i in license_list)
    add_one_license(ll, license_list[i]);
}

function get_license_list() {
  var basedir = '/opt/optional_software_installers';
  try {
    var software_directories = fs.readdirSync(basedir);
  } catch (ex) {
    alert(ex);
    return [];
  };

  var list = [];

  for (var i in software_directories) {
    var dir_fullpath = basedir + '/' + software_directories[i];
    if (! fs.statSync(dir_fullpath).isDirectory())
      continue;

    var license_path = dir_fullpath + '/license.json';
    try {
      var license_info = JSON.parse(fs.readFileSync(license_path));
    } catch(ex) { alert(ex); continue; }

    if (license_info
          && license_info.key
          && license_info.name
          && license_info.url) {
      list.push(license_info);
    } else {
      alert('License information was not in correct format in '
              + license_path);
    }
  }

  return list;
}

function open_external_link(e) {
  var child = child_process.spawn('x-www-browser',
                                  [ e.href ],
                                  { detached: true,
                                    stdio: [ 'ignore', 'ignore', 'ignore' ] });
  child.unref();
}

function read_config(config_json_path) {
  var config;

  try {
    config = JSON.parse( fs.readFileSync(config_json_path) );
  } catch (ex) {
    if (ex.code !== 'ENOENT') {
      alert(ex);
      return false;
    } else {
      config = { allow_login: 'localusers' };
    }
  }

  return config;
}

function set_form_values_from_config(config) {
  [].forEach.call(document.querySelectorAll('input[name=allow_login'),
                  function(e) {
                    if (e.getAttribute('value') === config.allow_login)
                      e.setAttribute('checked', 'checked'); });
}

var config = read_config(config_json_path);
if (!config) { process.exit(1); }

add_licenses(get_license_list());

set_form_values_from_config(config);

// in the end print configuration data as json
document.querySelector('input[id=done_button]')
        .addEventListener('click', done);
