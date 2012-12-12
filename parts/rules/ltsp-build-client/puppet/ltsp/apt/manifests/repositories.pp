class apt::repositories {
  include apt

  # XXX this should come from somewhere else (and be something else)
  $version = 'current'

  # define some apt repositories for use
  @apt::repository {
    'liitu':
      aptline => "http://repo.opinsys.fi/$lsbdistcodename/$version/liitu/ /";

    'partner':
      aptline => "http://archive.canonical.com/ubuntu $lsbdistcodename partner";
  }
}
