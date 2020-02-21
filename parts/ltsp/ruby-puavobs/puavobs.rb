require_relative 'puavobs-vendor/bundler/setup.rb'

## Standard libraries.
require 'base64'
require 'json'
require 'rexml/document'
require 'securerandom'
require 'tempfile'
require 'uri'

## 3rd-party libraries.
require 'highline/import'
require 'http'

module PuavoBS

  def self.basic_auth(username, password)
    basic_auth_creds = Base64.strict_encode64("#{username}:#{password}")
    "Basic #{basic_auth_creds}"
  end

  def self.get_api_url(path)
    uri = IO.popen([ 'puavo-resolve-api-server', '--writable' ]) do |io|
      output = io.read().strip()
      io.close()
      $?.success? ? URI(output) : nil
    end
    raise "failed to resolve the address of the API server" if uri.nil?
    uri.path = path
    uri.to_s
  end

  def self.get_puavo_url(path)
    server = File.read('/etc/puavo/domain').strip()
    uri = URI("https://#{server}")
    uri.path = path
    uri.to_s
  end

  def self.check_response_code(code)
    if !code.between?(200, 206) && code != 302 then
      raise "request failed with status code #{code}"
    end
  end

  def self.get_school(admin_username, admin_password, school_id)
    url = self.get_puavo_url("/users/schools/#{school_id}.json")
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:json)
      .get(url)
    self.check_response_code(response.code)
    JSON.parse(response.body)
  end

  def self.get_schools(admin_username, admin_password)
    school_ids = self.get_school_ids(admin_username, admin_password)
    return [] if school_ids.empty?

    school_ids.collect() do |school_id|
      self.get_school(admin_username, admin_password, school_id)
    end
  end

  def self.get_school_and_device_ids(admin_username, admin_password, hostname)
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:json)
      .get(self.get_api_url("/v3/devices/#{hostname}"))
    self.check_response_code(response.code)
    device_json = JSON.parse(response.body)
    school_id = Integer(/^puavoId=([0-9]+),/.match(device_json['school_dn'])[1])
    device_id = Integer(device_json['puavo_id'])
    [school_id, device_id]
  end

  def self.get_device_json(admin_username, admin_password, hostname)
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:json)
      .get(self.get_api_url("/v3/devices/#{hostname}"))
    self.check_response_code(response.code)
    JSON.parse(response.body)
  end

  def self.get_preferred_boot_image(hostname)
    self.get_device_json(hostname)['preferred_boot_image']
  end

  def self.get_school_ids(admin_username, admin_password)
    puavo_id = Integer(File.read('/etc/puavo/id').strip())
    url = self.get_puavo_url("/devices/servers/#{puavo_id}.xml")
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:xml)
      .get(url)
    self.check_response_code(response.code)
    doc = REXML::Document.new(response.body)
    doc.elements.collect('/server/puavoSchools/puavoSchool') do |element|
      Integer(/^puavoId=([0-9]+),/.match(element.text())[1])
    end
  end

  def self.ask_admin_credentials()
    puavo_domain = File.read('/etc/puavo/domain').strip()
    say("Enter administrator credentials for organization #{puavo_domain}")
    username = ask('Username: ')
    password = ask('Password: ') { |q| q.echo = '*' }
    [username, password]
  end

  def self.ask_school(admin_username, admin_password)
    school_ids = self.get_school_ids(admin_username, admin_password)
    return nil if school_ids.empty?

    schools = school_ids.collect() do |school_id|
      self.get_school(admin_username, admin_password, school_id)
    end

    say("Select the school which the device shall be registered to")
    choose() do |menu|
      schools.each() do |school|
        menu.choice(school['name']) { school }
      end
    end
  end

  def self.register_device(admin_username, admin_password, school_id,
                           hostname, mac, hosttype, tags)
    url = self.get_puavo_url("/devices/#{school_id}/devices.json")
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:json)
      .post(url, :json => {
              "puavoHostname"   => hostname,
              "macAddress"      => Array(mac),
              "puavoTag"        => tags.join(" "),
              "puavoDeviceType" => hosttype,
              "classes"         => ["puavoNetbootDevice"]
            })
    self.check_response_code(response.code)
    response.code
  end

  def self.unregister_device(admin_username, admin_password, hostname)
    school_id, device_id = self.get_school_and_device_ids(admin_username, admin_password, hostname)
    url = self.get_puavo_url("/devices/#{school_id}/devices/#{device_id}.xml")
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .delete(url)
    self.check_response_code(response.code)
    response.code
  end

  def self.get_role_ids(admin_username, admin_password, school_id)
    url = self.get_puavo_url("/users/#{school_id}/roles.xml")
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:xml)
      .get(url)
    self.check_response_code(response.code)
    doc = REXML::Document.new(response.body)
    doc.elements.collect('/roles/role/dn') do |element|
      Integer(/^puavoId=([0-9]+),/.match(element.text())[1])
    end
  end

  def self.create_testuser(admin_username, admin_password, school,
                           testuser_username='test.user.**********')
    testuser_username.gsub!('*') { SecureRandom.hex(1) }
    testuser_password = SecureRandom.hex(32)

    ldap_base = File.read('/etc/puavo/ldap/base').strip()
    school_dn = "puavoId=#{ school['puavo_id'] },ou=Groups,#{ ldap_base }"
    user = {
      'first_name' => 'test',
      'last_name'  => 'user',
      'password'   => testuser_password,
      'roles'      => [ 'testuser' ],
      'school_dns' => [ school_dn ],
      'username'   => testuser_username,
    }

    url = self.get_api_url('/v3/users')
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:json)
      .post(url, :json => user)
    self.check_response_code(response.code)
    [testuser_username, testuser_password]
  end

  def self.get_user_id(admin_username, admin_password, user_username)
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .accept(:json)
      .get(self.get_api_url("/v3/users/#{user_username}"))
    self.check_response_code(response.code)
    user_json = JSON.parse(response.body)
    Integer(/^puavoId=([0-9]+),/.match(user_json['dn'])[1])
  end

  def self.remove_user(admin_username, admin_password, user_username)
    user_id = self.get_user_id(admin_username, admin_password, user_username)

    url = self.get_api_url("/v3/users/#{ user_username }/mark_for_deletion")
    response = HTTP
      .auth(self.basic_auth(admin_username, admin_password))
      .delete(url)
    self.check_response_code(response.code)
    response.code
  end

  def self.virsh_define_testclient(orig_hostname=nil)
    hostname = orig_hostname
    if hostname.nil?
      hostname = "test-device-#{SecureRandom.hex(10)}"
    end
    uuid = SecureRandom.uuid()
    mac = 'aa:cc'
    4.times { mac += ":#{SecureRandom.hex(1)}" }

    xml = <<EOF
<domain type='kvm'>
  <name>#{hostname}</name>
  <uuid>#{uuid}</uuid>
  <memory unit='KiB'>20971552</memory>
  <currentMemory unit='KiB'>20971552</currentMemory>
  <vcpu placement='static'>1</vcpu>
  <os>
    <type arch='x86_64' machine='pc-1.0'>hvm</type>
    <boot dev='network'/>
  </os>
  <features>
    <acpi/>
    <apic/>
    <pae/>
  </features>
  <clock offset='utc'/>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <devices>
    <emulator>/usr/bin/kvm</emulator>
    <controller type='usb' index='0'>
    </controller>
    <controller type='ide' index='0'>
    </controller>
    <interface type='bridge'>
      <mac address='#{mac}'/>
      <source bridge='wlan0'/>
      <model type='e1000'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <video>
      <model type='vga' vram='8192' heads='1'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x02' function='0x0'/>
    </video>
    <memballoon model='virtio'>
    </memballoon>
  </devices>
</domain>
EOF

    tmpfile = Tempfile.new([hostname, '.xml'])
    begin
      File.write(tmpfile.path, xml)
      pid = Process.spawn('virsh', 'define', tmpfile.path, STDOUT => '/dev/null')
      Process.wait(pid)
      success = $?.success?
    ensure
      tmpfile.close()
      tmpfile.unlink()
    end
    if orig_hostname.nil?
      success ? [hostname, mac] : nil
    else
      success ? mac : nil
    end
  end

  def self.get_org_json()
    puavo_domain = File.read('/etc/puavo/domain').strip()
    puavo_ldap_dn = File.read('/etc/puavo/ldap/dn').strip()
    puavo_ldap_password = File.read('/etc/puavo/ldap/password').strip()
    response = HTTP
      .accept(:json)
      .auth(self.basic_auth(puavo_ldap_dn, puavo_ldap_password))
      .get(self.get_api_url("/v3/organisations/#{puavo_domain}"))
    self.check_response_code(response.code)
    JSON.parse(response.body)
  end

end
