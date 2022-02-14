class packages::fasttrack {
  # This list is used by apt::fasttrack so that these packages will be picked
  # up from fasttrack instead of the usual channels.  The inclusion of a
  # package on this list does not trigger the installation of a package,
  # that has to be defined elsewhere.

  $package_list = []
}
