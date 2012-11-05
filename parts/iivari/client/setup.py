# -*- encoding: utf-8 -*-
from distutils.core import setup
import os, glob

def read(fname):
    return open(os.path.join(os.path.dirname(__file__), fname)).read()

setup(name="iivari-client",
      version="1.3.2",
      maintainer="Juha Erkkilä",
      maintainer_email="Juha.Erkkila@opinsys.fi",
      url="https://github.com/opinsys/iivari/",
      license="GPL-2",
      description="Webbrowser for iivari info screens",
      long_description=read("README.md"),
      packages=["iivari", "iivari/logger"],
      scripts=["bin/start_infotv",
               "bin/iivari-kiosk",
               "bin/iivari-display_off",
               "bin/iivari-display_on",
               "bin/iivari-display_test_pattern"],
      data_files=[("/usr/share/iivari/assets", glob.glob("iivari/assets/*")),
                  ("/usr/share/applications", ["iivari-infotv.desktop"]),
                  #("/etc", ["iivarirc"])
                  ],
      )
