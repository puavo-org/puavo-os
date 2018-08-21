class packages::backports {
  # This list is used by apt::backports so that these packages will be picked
  # up from backports instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.
  $package_list = $debianversioncodename ? {
                    'stretch' => [
                                 # the libreoffice bundle
                                 'firebird3.0-common'
                                 , 'firebird3.0-common-doc'
                                 , 'firebird3.0-server-core'
                                 , 'fonts-liberation2'
                                 , 'libfbclient2'
                                 , 'libib-util'
                                 , 'libreoffice'
                                 , 'libreoffice-avmedia-backend-gstreamer'
                                 , 'libreoffice-base'
                                 , 'libreoffice-base-core'
                                 , 'libreoffice-base-drivers'
                                 , 'libreoffice-calc'
                                 , 'libreoffice-common'
                                 , 'libreoffice-core'
                                 , 'libreoffice-draw'
                                 , 'libreoffice-gnome'
                                 , 'libreoffice-gtk3'
                                 , 'libreoffice-help-de'
                                 , 'libreoffice-help-en-gb'
                                 , 'libreoffice-help-fi'
                                 , 'libreoffice-help-fr'
                                 , 'libreoffice-help-sv'
                                 , 'libreoffice-impress'
                                 , 'libreoffice-java-common'
                                 , 'libreoffice-l10n-de'
                                 , 'libreoffice-l10n-en-gb'
                                 , 'libreoffice-l10n-en-za'
                                 , 'libreoffice-l10n-fi'
                                 , 'libreoffice-l10n-fr'
                                 , 'libreoffice-l10n-sv'
                                 , 'libreoffice-math'
                                 , 'libreoffice-ogltrans'
                                 , 'libreoffice-pdfimport'
                                 , 'libreoffice-report-builder'
                                 , 'libreoffice-report-builder-bin'
                                 , 'libreoffice-script-provider-bsh'
                                 , 'libreoffice-script-provider-js'
                                 , 'libreoffice-script-provider-python'
                                 , 'libreoffice-sdbc-firebird'
                                 , 'libreoffice-sdbc-hsqldb'
                                 , 'libreoffice-sdbc-postgresql'
                                 , 'libreoffice-style-breeze'
                                 , 'libreoffice-style-galaxy'
                                 , 'libreoffice-style-tango'
                                 , 'libreoffice-wiki-publisher'
                                 , 'libreoffice-writer'
                                 , 'libtommath1'
                                 , 'python3-uno'
                                 , 'uno-libs3'
                                 , 'ure'

                                 , 'libssh-4'
                                 , 'remmina'
                                 ],
                    default   => [],
                  }
}
