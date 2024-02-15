Facter.add('deb_host_arch') do
  confine 'os' do |os|
    os['family'] == 'Debian'
  end
  setcode do
    Facter::Core::Execution.execute('/usr/bin/dpkg-architecture -q DEB_HOST_ARCH')
  end
end
