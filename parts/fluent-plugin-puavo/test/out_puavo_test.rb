
require "fluent/test"
require "fileutils"
require "debugger"
require "webmock/test_unit"
require_relative "../out_puavo"

WebMock.disable_net_connect!

class PuavoWrapperTest < PuavoFluent::PuavoWrapper
end

class PuavoOutput < Test::Unit::TestCase

 def setup
    Fluent::Test.setup
    @driver = nil
    @test_config = "
      puavo_hostname testhostname
      puavo_domain testdomain
      puavo_topdomain testtopdomain
      puavo_ldap_dn testdn
      puavo_ldap_password testpw
    "
  end

  def driver(tag='test', conf='')
    conf = @test_config + conf
    @driver ||= Fluent::Test::BufferedOutputTestDriver.new(PuavoWrapperTest, tag).configure(conf)
  end

  def test_laptop_gets_rest
    driver "test", "puavo_hosttype laptop"
    assert_equal PuavoFluent::RestOut, driver.instance.plugin.class
  end

  def test_bootserver_gets_rest
    driver "test", "puavo_hosttype bootserver"
    assert_equal PuavoFluent::RestOut, driver.instance.plugin.class
  end

  def test_fatclient_gets_autoforward
    driver "test", "puavo_hosttype fatclient"
    assert_equal PuavoFluent::AutoForward, driver.instance.plugin.class
  end

  def test_ltspserver_gets_autoforward
    driver "test", "puavo_hosttype fatclient"
    assert_equal PuavoFluent::AutoForward, driver.instance.plugin.class
  end

  def test_rest_for_laptop

    got_request = false
    stub_request(:any, /testhost/).to_return do
      got_request = true
      {:body => "abc", :status => 200, :headers => { 'Content-Length' => 3 }}
    end

    d = driver "test", "
      puavo_hosttype laptop

      rest_host testhost
      rest_port 80
      "
    time = Time.parse("2011-01-02 13:14:15").to_i
    d.emit({ "foo" => "bar" }, time)
    d.run
    assert got_request
  end

  def test_can_customize_laptop_flush_interval
    driver "test", "
    puavo_hosttype laptop

    <device laptop>
      flush_interval 6s
    </device>

    <device fatclient>
      flush_interval 16s
    </device>
    "

    assert_equal "6s", driver.instance.config["flush_interval"]
  end

  def test_can_customize_fatclient_flush_interval
    driver "test", "
    puavo_hosttype fatclient

    <device laptop>
      flush_interval 6s
    </device>

    <device fatclient>
      flush_interval 16s
    </device>
    "

    assert_equal "16s", driver.instance.config["flush_interval"]
  end

  def test_emit_injects_device_info
    stub_request(:any, /testhost/).to_return do |req|
      data = JSON.parse(req.body)
      assert_equal [{"foo"=>"bar", "_tag"=>"test", "_time"=>1293966855}], data
      {:body => "abc", :status => 200}
    end

    d = driver "test", "
      puavo_hosttype laptop

      rest_host testhost
      rest_port 80
      "
    time = Time.parse("2011-01-02 13:14:15").to_i
    d.emit({ "foo" => "bar" }, time)

  end
end
