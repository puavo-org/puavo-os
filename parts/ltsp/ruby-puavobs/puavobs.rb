## Standard libraries.
require 'json'
require 'net/https'
require 'rexml/document'
require 'securerandom'
require 'tempfile'

## 3rd-party libraries.
require 'highline/import'

module PuavoBS

  def PuavoBS.get_school(username, password, school_id)
    server = File.read('/etc/puavo/domain').strip()

    https              = Net::HTTP.new(server, 443)
    https.use_ssl      = true
    https.ca_path      = '/etc/ssl/certs'
    https.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    https.start() do |https|
      request = Net::HTTP::Get.new("/users/schools/#{school_id}.json")
      request.basic_auth(username, password)
      request['Accept'] = 'application/json'

      response = https.request(request)
      response.value()

      JSON.parse(response.body())
    end
  end

  def PuavoBS.get_school_and_device_ids(hostname)
    uri = IO.popen('puavo-resolve-api-server') do |io|
      output = io.read().strip()
      io.close()
      $?.success? ? URI(output) : nil
    end

    https = Net::HTTP.new(uri.host, uri.port)
    https.use_ssl = true
    https.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    device_json = https.start() do |https|
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

  def PuavoBS.get_school_ids(username, password)
    puavo_id = Integer(File.read('/etc/puavo/id').strip())
    server = File.read('/etc/puavo/domain').strip()

    https              = Net::HTTP.new(server, 443)
    https.use_ssl      = true
    https.ca_path      = '/etc/ssl/certs'
    https.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    schools = https.start() do |https|
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

  def PuavoBS.ask_admin_credentials()
    puavo_domain = File.read('/etc/puavo/domain').strip()
    say("Enter administrator credentials for organization #{puavo_domain}")
    username = ask('Username: ')
    password = ask('Password: ') { |q| q.echo = '*' }
    [username, password]
  end

  def PuavoBS.ask_school(username, password)
    school_ids = PuavoBS.get_school_ids(username, password)
    school_names = school_ids.collect() do |school_id|
      PuavoBS.get_school(username, password, school_id)["name"]
    end

    say("Select the school which the device shall be registered to")
    choose() do |menu|
      school_ids.each_with_index() do |id, i|
        menu.choice(school_names[i]) { [school_names[i], id] }
      end
    end
  end

  def PuavoBS.register_device(username, password, school_id,
                              hostname, mac, hosttype, tags)
    server = File.read('/etc/puavo/domain').strip()

    https              = Net::HTTP.new(server, 443)
    https.use_ssl      = true
    https.ca_path      = '/etc/ssl/certs'
    https.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    register_json = JSON.generate("puavoHostname"   => hostname,
                                  "macAddress"      => mac,
                                  "puavoTag"        => tags,
                                  "puavoDeviceType" => hosttype,
                                  "classes"         => ["puavoNetbootDevice"])

    https.start() do |https|
      request = Net::HTTP::Post.new("/devices/#{school_id}/devices.json")
      request.basic_auth(username, password)
      request['Content-Type'] = 'application/json'
      request['Accept'] = 'application/json'
      request.body = register_json

      response = https.request(request)
      response_code = Integer(response.code)
      response.value()
      response_code
    end
  end

  def PuavoBS.unregister_device(username, password, hostname)
    school_id, device_id = PuavoBS.get_school_and_device_ids(hostname)
    puavo_domain = File.read('/etc/puavo/domain').strip()

    https = Net::HTTP.new(puavo_domain, 443)
    https.use_ssl = true
    https.verify_mode  = OpenSSL::SSL::VERIFY_PEER
    https.verify_depth = 5

    https.start() do |https|
      path = "/devices/#{school_id}/devices/#{device_id}.xml"
      request = Net::HTTP::Delete.new(path)
      request.basic_auth(username, password)

      response = https.request(request)
      response_code = Integer(response.code)
      response.value()
      response_code
    end
  end

  def PuavoBS.virsh_define_testclient(hostname)
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
