## Standard libraries.
require 'json'
require 'net/https'
require 'rexml/document'

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

  def PuavoBS.ask_school(username, password)
    school_ids = PuavoBS.get_schools_ids(username, password)
    school_names = school_ids.collect() do |school_id|
      PuavoBS.get_school(username, password, school_id)["name"]
    end

    say("\nWhich school the device shall be registered to?")
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
      response.value()
    end
  end

  def PuavoBS.get_schools_ids(username, password)
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

end
