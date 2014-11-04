## Standard libraries.
require 'json'
require 'net/https'
require 'rexml/document'
require 'securerandom'
require 'tempfile'

## 3rd-party libraries.
require 'highline/import'

module PuavoBS

  def self.with_https(host, port, &block)
    https              = Net::HTTP.new(host, port)
    https.use_ssl      = true
    https.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5
    https.start(&block)
  end

  def self.with_puavo_https(&block)
    server = File.read('/etc/puavo/domain').strip()

    self.with_https(server, 443, &block)
  end

  def self.with_api_https(&block)
    uri = IO.popen('puavo-resolve-api-server') do |io|
      output = io.read().strip()
      io.close()
      $?.success? ? URI(output) : nil
    end

    self.with_https(uri.host, uri.port, &block)
  end

  def self.get_school(username, password, school_id)
    self.with_puavo_https() do |https|
      request = Net::HTTP::Get.new("/users/schools/#{school_id}.json")
      request.basic_auth(username, password)
      request['Accept'] = 'application/json'

      response = https.request(request)
      response_code = Integer(response.code)
      if response_code == 302 then
        ## Puavo seems to respond with 302 in some, yet successful
        ## cases.
        return JSON.parse(response.body())
      end
      response.value()

      JSON.parse(response.body())
    end
  end

  def self.get_school_and_device_ids(hostname)
    device_json = self.with_api_https() do |https|
      request = Net::HTTP::Get.new("/v3/devices/#{hostname}")
      request['Accept'] = 'application/json'

      response = https.request(request)
      response.value()

      JSON.parse(response.body())
    end

    school_id = Integer(/^puavoId=([0-9]+),/.match(device_json['school_dn'])[1])
    device_id = Integer(device_json['puavo_id'])
    [school_id, device_id]
  end

  def self.get_school_ids(username, password)
    puavo_id = Integer(File.read('/etc/puavo/id').strip())

    schools = self.with_puavo_https() do |https|
      request = Net::HTTP::Get.new("/devices/servers/#{puavo_id}.xml")
      request.basic_auth(username, password)
      request['Accept'] = 'application/xml'

      response = https.request(request)
      response.value()

      doc = REXML::Document.new(response.body())
      doc.elements.collect('/server/puavoSchools/puavoSchool') do |element|
        Integer(/^puavoId=([0-9]+),/.match(element.text())[1])
      end
    end
  end

  def self.ask_admin_credentials()
    puavo_domain = File.read('/etc/puavo/domain').strip()
    say("Enter administrator credentials for organization #{puavo_domain}")
    username = ask('Username: ')
    password = ask('Password: ') { |q| q.echo = '*' }
    [username, password]
  end

  def self.ask_school(username, password)
    school_ids = self.get_school_ids(username, password)
    return nil if school_ids.empty?

    school_names = school_ids.collect() do |school_id|
      self.get_school(username, password, school_id)["name"]
    end

    say("Select the school which the device shall be registered to")
    choose() do |menu|
      school_ids.each_with_index() do |id, i|
        menu.choice(school_names[i]) { [school_names[i], id] }
      end
    end
  end

  def self.register_device(username, password, school_id,
                              hostname, mac, hosttype, tags)
    register_json = JSON.generate("puavoHostname"   => hostname,
                                  "macAddress"      => mac,
                                  "puavoTag"        => tags,
                                  "puavoDeviceType" => hosttype,
                                  "classes"         => ["puavoNetbootDevice"])

    self.with_puavo_https() do |https|
      request = Net::HTTP::Post.new("/devices/#{school_id}/devices.json")
      request.basic_auth(username, password)
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = register_json

      response = https.request(request)
      response.value()
      Integer(response.code)
    end
  end

  def self.unregister_device(username, password, hostname)
    school_id, device_id = self.get_school_and_device_ids(hostname)

    self.with_puavo_https() do |https|
      path = "/devices/#{school_id}/devices/#{device_id}.xml"
      request = Net::HTTP::Delete.new(path)
      request.basic_auth(username, password)

      response = https.request(request)
      response.value()
      Integer(response.code)
    end
  end

  def self.get_role_ids(username, password, school_id)
    self.with_puavo_https() do |https|
      request = Net::HTTP::Get.new("/users/#{school_id}/roles.xml")
      request.basic_auth(username, password)
      request['Accept'] = 'application/xml'

      response = https.request(request)
      response.value()

      doc = REXML::Document.new(response.body())
      doc.elements.collect('/roles/role/dn') do |element|
        Integer(/^puavoId=([0-9]+),/.match(element.text())[1])
      end
    end
  end

  def self.create_testuser(username, password, school_id)
    role_ids = self.get_role_ids(username, password, school_id)
    if role_ids.empty? then
      return []
    end

    testuser_role_id  = role_ids[0]
    testuser_username = "test.user.#{SecureRandom.hex(10)}"
    testuser_password = SecureRandom.hex(32)

    self.with_puavo_https() do |https|
      request = Net::HTTP::Post.new("/users/#{school_id}/users")
      request.basic_auth(username, password)
      form_data = {
        "user[givenName]"                 => "test",
        "user[sn]"                        => "user",
        "user[uid]"                       => testuser_username,
        "user[puavoEduPersonAffiliation]" => "testuser",
        "user[role_ids][]"                => testuser_role_id,
        "user[new_password]"              => testuser_password,
        "user[new_password_confirmation]" => testuser_password,
      }
      request.set_form_data(form_data)

      response = https.request(request)
      response_code = Integer(response.code)
      if response_code == 302 then
        ## Puavo seems to redirect on success.
        break
      end
      response.value()
    end
    [testuser_username, testuser_password]
  end

  def self.get_user_id(username, password, user_username)
    user_json = self.with_api_https() do |https|
      request = Net::HTTP::Get.new("/v3/users/#{user_username}")
      request.basic_auth(username, password)
      request['Accept'] = 'application/json'

      response = https.request(request)
      response.value()

      JSON.parse(response.body())
    end
    Integer(/^puavoId=([0-9]+),/.match(user_json['dn'])[1])
  end

  def self.remove_user(username, password, school_id, user_username)
    user_id = self.get_user_id(username, password, user_username)

    self.with_puavo_https() do |https|
      path = "/users/#{school_id}/users/#{user_id}.xml"
      request = Net::HTTP::Delete.new(path)
      request.basic_auth(username, password)

      response = https.request(request)
      response.value()
      Integer(response.code)
    end
  end

  def self.virsh_define_testclient(hostname)
    uuid = SecureRandom.uuid()
    mac = 'aa:cc'
    4.times { mac += ":#{SecureRandom.hex(1)}" }

    xml = <<EOF
<domain type='kvm'>
  <name>#{hostname}</name>
  <uuid>#{uuid}</uuid>
  <memory unit='KiB'>524288</memory>
  <currentMemory unit='KiB'>524288</currentMemory>
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
      <source bridge='ltsp0'/>
      <model type='e1000'/>
    </interface>
    <serial type='pty'>
      <target port='0'/>
    </serial>
    <console type='pty'>
      <target type='serial' port='0'/>
    </console>
    <video>
      <model type='vga' vram='8192' heads='1'>
        <acceleration accel3d='no' accel2d='yes'/>
      </model>
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
    success ? mac : nil
  end

end
