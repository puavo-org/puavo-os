class apt::repositories {
  include apt

  # define some apt keys and repositories for use
  @apt::repository {
    'partner':
      aptline => "http://archive.canonical.com/ubuntu $lsbdistcodename partner";
  }
}
