var child_process = require('child_process');
var fs = require('fs');

function done(e) {
  var response = document.forms[0].elements;
  var conf = {};

  conf.allow_login = response.allow_login.value;

  conf.licenses = {
    'adobe_acroread':     response['licenses[adobe_acroread]'    ].checked,
    'adobe_flash_plugin': response['licenses[adobe_flash_plugin]'].checked,
  };

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

  process.stdout.write(JSON.stringify(conf) + "\n");
  process.exit(0);
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

  for (i in software_directories) {
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

var license_list = get_license_list();

// open license links in an external browser
var license_links = document.querySelectorAll('a[class=license_link]');
[].forEach.call(license_links,
                function(el) {
                  el.addEventListener('click',
				      function(e) {
					e.preventDefault();
					open_external_link(el); }) });

// in the end print configuration data as json
document.querySelector('input[id=done_button]')
        .addEventListener('click', done);
