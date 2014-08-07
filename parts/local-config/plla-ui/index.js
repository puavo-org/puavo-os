var fs = require('fs');

function get_license_list() {
  var datadir = '/usr/share/puavo-ltsp-client/restricted-packages';
  var packdir = '/var/lib/puavo-ltsp-client-restricted-packages';

  try {
    var software_directories = fs.readdirSync(datadir);
  } catch (ex) {
    alert(ex);
    return [];
  };

  var license_list = [];

  for (var i in software_directories) {
    var packagename = software_directories[i];
    var dir_fullpath = datadir + '/' + packagename;
    if (! fs.statSync(dir_fullpath).isDirectory())
      continue;

    var licenseinfo_path = dir_fullpath + '/license.json';
    var md5sum_file_path = dir_fullpath + '/upstream.pack.md5sum';
    try {
      var license_name = JSON.parse(fs.readFileSync(licenseinfo_path)).name;
      var md5sum = fs.readFileSync(md5sum_file_path)
                     .toString().replace(/\n$/, '');
    } catch(ex) { alert(ex); continue; }

    var upstream_license_path
      = packdir + '/' + packagename + '/' + md5sum + '/upstream.license';

    license_list[license_name] = upstream_license_path;
  }

  return license_list;
}

var accept_button = document.querySelector('*[id=accept_button]');

accept_button.addEventListener('click',
                               function(e) { process.exit(0); });

var license_list = get_license_list();
