
require "fileutils"
require "tmpdir"
require "etc"
require "test/unit"

require "./lib/puavo/etc"

class TestPuavoEtcReader < Test::Unit::TestCase

  def test_read_string
    Dir.mktmpdir do |dir|
      File.write(dir + "/domain", "testdomain\n")

      pe = PuavoEtc.new(dir)
      assert_equal(pe.domain, "testdomain")

    end
  end

  def test_read_fixnum
    Dir.mktmpdir do |dir|
      File.write(dir + "/id", "123\n")
      pe = PuavoEtc.new(dir)

      assert_equal(pe.id, 123)
    end
  end


  def test_read_subdir
    Dir.mktmpdir do |dir|
      FileUtils.mkdir_p(dir + "/ldap")
      File.write(dir + "/ldap/dn", "testdn\n")
      pe = PuavoEtc.new(dir)

      assert_equal(pe.ldap_dn, "testdn")
    end
  end

  def test_write
    Dir.mktmpdir do |dir|
      pe = PuavoEtc.new(dir)
      pe.write :id, 123

      assert_equal(File.read(dir + "/id"), "123\n")
    end
  end

  def test_write_subdir
    Dir.mktmpdir do |dir|
      pe = PuavoEtc.new(dir)
      pe.write :ldap_dn, "newdn"

      assert_equal(File.read(dir + "/ldap/dn"), "newdn\n")
    end
  end

  def test_write_clears_cache
    Dir.mktmpdir do |dir|
      File.write(dir + "/id", "123\n")
      pe = PuavoEtc.new(dir)
      pe.id # Cache fill
      pe.write :id, 321

      assert_equal(pe.id, 321)
    end
  end

  # XXX: This test requires root permissions and a puavo group
  def test_password_permissions
    Dir.mktmpdir do |dir|
      pe = PuavoEtc.new(dir)
      pe.write :ldap_password, "secret"

      stat = File.stat(dir + "/ldap/password")
      mode = sprintf("%o", stat.mode)
      assert_equal(mode, "100640")
      assert_equal(Etc.getgrgid(stat.gid).name, "puavo")
    end
  end

end
