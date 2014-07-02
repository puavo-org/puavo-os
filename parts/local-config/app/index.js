function done(e) {
  var response = document.forms[0].elements;
  var conf = {};

  conf.allow_login = response.allow_login.value;

  conf.licenses = {
    'adobe_acroread':     response['licenses[adobe_acroread]'    ].checked,
    'adobe_flash_plugin': response['licenses[adobe_flash_plugin]'].checked,
  };

  conf.local_user = {
    localuser_admin_rights:   response.localuser_admin_rights.checked,
    localuser_name:           response.localuser_name.value,
    localuser_password:       response.localuser_password.value,
    localuser_password_again: response.localuser_password_again.value,
  };

  conf.superlaptop_mode = response.superlaptop_mode.checked;

  process.stdout.write(JSON.stringify(conf) + "\n");
  process.exit(0);
}

document.querySelector('input[id=done_button]')
        .addEventListener('click', done);
