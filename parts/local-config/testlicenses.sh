#!/bin/sh

set -eu

basedir="/opt/optional_software_installers"

mkdir -p "$basedir"

add_license() {
  name=$1

  mkdir -p "$basedir/$name"
  cat > "$basedir/$name/license.json"
}

add_license adobe_acroreader <<'EOF'
{
  "key": "adobe_acroreader",
  "name": "Adobe Acroreader",
  "url": "http://www.adobe.com/fi/products/reader/distribution.html"
}
EOF

add_license adobe_flash <<'EOF'
{
  "key": "adobe_flashplugin",
  "name": "Adobe Flashplugin",
  "url": "http://wwwimages.adobe.com/www.adobe.com/content/dam/Adobe/en/legal/licenses-terms/pdf/FlashPlayer_12_0_en.pdf"
}
EOF

add_license chrome <<'EOF'
{
  "key": "chrome",
  "name": "Chrome",
  "url": "https://www.google.com/intl/en/chrome/browser/privacy/eula_text.html"
}
EOF

add_license cmaptools <<'EOF'
{
  "key": "cmaptools",
  "name": "Cmaptools",
  "url": "http://cmap.ihmc.us/download/license_client.php"
}
EOF

add_license dropbox <<'EOF'
{
  "key": "dropbox",
  "name": "Dropbox",
  "url": "https://www.dropbox.com/install"
}
EOF

add_license google_earth <<'EOF'
{
  "key": "google_earth",
  "name": "Google Earth",
  "url": "http://earth.google.com/intl/en-US/license.html"
}
EOF

add_license oracle_java <<'EOF'
{
  "key": "oracle_java",
  "name": "Oracle Java",
  "url": "http://www.oracle.com/technetwork/java/javase/terms/license/index.html"
}
EOF

add_license skype <<'EOF'
{
  "key": "skype",
  "name": "Skype",
  "url": "http://www.skype.com/en/legal/tou/#4"
}
EOF

add_license spotify <<'EOF'
{
  "key": "spotify",
  "name": "Spotify",
  "url": "http://community.spotify.com/t5/Help-Desktop-Linux-Mac-and/What-license-does-the-linux-spotify-client-use/td-p/173356/page/3"
}
EOF
