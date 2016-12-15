class chromium::office365_tweaks {
  include ::chromium

  # Microsoft Office 365 is broken with Chrome/Chromium when the default
  # user-agent string is used (containing "Linux").
  # Our Chrome (on Linux) user agent string is normally
  # "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36"
  # depending on version, of course.  We must replace the "Linux" with "CrOS"
  # in the following way, so that our system appears as a Chromebook.
  $user_agent = 'Mozilla/5.0 (X11; CrOS x86_64 8872.70.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/55.0.2883.87 Safari/537.36'

  # Use the special user-agent string only for Microsoft Office 365 domains.
  # This list is constructed from information in
  # https://support.office.com/en-us/article/managing-Office-365-endpoints-99cab9d4-ef59-4207-9f2b-3728eb46bf9a
  # ("See PAC file examples using the current list of endpoints").
  $office365_domains = [ 'live.com'
                       , 'lync.com'
                       , 'microsoftonline.com'
                       , 'microsoftonline-p.net'
                       , 'office365.com'
                       , 'office.com'
                       , 'office.net'
                       , 'outlook.com'
                       , 'sharepoint.com'
                       , 'skype.com'
                       , 'svc.ms'
                       , 'windows.net' ]

  # See http://superuser.com/questions/303929/does-office-365-work-properly-on-ubuntu-chrome-os
  # for more information.

  chromium::install_policy {
    'office365_tweaks':
      require => Chromium::Install_policy['extension_install_forcelist'];
  }
}
