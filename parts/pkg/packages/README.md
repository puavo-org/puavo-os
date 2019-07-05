# Puavo package installers

To build all installers, run:

    make

The packages can be tested/installed with

    puavo-pkg install examplepkg.tar.gz

# Updating the packages

To update/remove packages according to specifications in puavo-conf, run:

    puavo-pkg-update

It is possible to update/remove only one package by giving the package name
as a command argument.

# Fixing the installers

The installers download software from the internet and install them.
Thus, we expect them to break from time to time.  We anticipate that the
most common problem is that upstream changes URLs, or upstream pack contents
change, meaning that checksums calculated from upstream packs also change.

Note that not all packages use direct URLs or checksums... that is another
source of possible problems, because versions in use may not match or old
versions are not updated to later versions.  URLs and checksums are not
used when it is known they change too rapidly (dropbox, google-chrome).

If URL needs fixing, ``upstream_pack_url`` contains the URL.  If
checksum needs fixing, ``upstream_pack_md5sum`` contains the checksum.
New URLs should be looked up from upstream.  On failed checksum checks,
``puavo-pkg`` reports the expected checksum and the actual checksum.
If the checksum needs an update, the situation should generally be
examined on why it is so and the resulting package installation should
be tested.
