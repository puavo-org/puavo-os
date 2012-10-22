#!/usr/bin/ruby

require "ldap"
require 'rubygems'
require 'yaml'

class LocateUser
  def get_servers(suffix, search_str)
    serverlist = ""
  
    conn = LDAP::SSLConn.new(host=@ldaphost, port=636)
    conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
  
    servers = Hash.new
    mountpoints = Hash.new
    name = suffix
  
    result = []
    conn.bind(@binddn, @bindpw) do
  
      begin
        domain = ""
  
        conn.search(suffix, LDAP::LDAP_SCOPE_BASE, "(objectClass=eduOrg)") {|e|
          domain = e.get_values('puavoDomain')[0]
        }
  
        conn.search(suffix, LDAP::LDAP_SCOPE_SUBTREE, "(objectClass=puavoServer)") {|e|
  	name = "#{e.get_values('cn')}"
          tags = e.get_values('puavoTag')
  
          if e.get_values('puavoExport')
            e.get_values('puavoExport').each {|export|
              if /\/home\/(.*)/.match(export)
                schoolcn=$1
                if tags && tags.include?(schoolcn)
                  mountpoints["#{schoolcn}*"] = "#{name}.#{domain}"
                else
                  if mountpoints[schoolcn]
                    mountpoints[schoolcn] << "#{name}.#{domain}"
                  else
                    mountpoints[schoolcn] = ["#{name}.#{domain}"]
                  end
                end
              end
            }
          end
  
        }
        conn.search(suffix, LDAP::LDAP_SCOPE_SUBTREE, "(&(objectClass=posixAccount)(|(displayName=#{search_str}*)(puavoReverseDisplayName=#{search_str}*)(mail=#{search_str}*)(phoneNumber=#{search_str})(uid=#{search_str}*)))") {|e|
  	name = "#{e.get_values('cn')}"
          home = "#{e.get_values('homeDirectory')}"
  
          if /\/home\/(.*)\//.match(home)
            schoolcn=$1
  
            if mountpoints["#{schoolcn}*"]
              result.push "#{mountpoints[schoolcn]} #{home} (*)"
            elsif mountpoints["#{schoolcn}"]
              if mountpoints["#{schoolcn}"].size > 1
                result.push "MONTA MAHDOLLISUUTTA: #{home}"
  
                mountpoints["#{schoolcn}"].each {|server|
                  result.push  "  #{server}"
                }
              else
                result.push "#{mountpoints[schoolcn]} #{home}"
              end
            end
          end
  
        }
      rescue LDAP::ResultError
        conn.perror("Virhe")
        result.push "Virhe"
      end  
    end
    return result
  end
  
  def initialize()
    if configurations = YAML.load_file("/etc/puavo/ldap.yml") rescue nil
    else
      puts "Not found LDAP configuration file (config/ldap.yml)"
      exit
    end
  
    @binddn = configurations["settings"]["ldap_server"]["bind_dn"]
    @bindpw = configurations["settings"]["ldap_server"]["password"]
    @ldaphost = configurations["settings"]["ldap_server"]["host"]
    @ldapuri = "ldap://#{@ldaphost}"
    @exclude = configurations["settings"]["tags"]["exclude_servers"]
  
    @tags = Hash.new
    @tags['all_servers'] = Array.new
  end
  
  def query( org, search_str )
    conn = LDAP::SSLConn.new(host=@ldaphost, port=636)
    conn.set_option(LDAP::LDAP_OPT_PROTOCOL_VERSION, 3)
    allresults = []
    conn.bind(@binddn, @bindpw) do
      begin
        conn.search("", LDAP::LDAP_SCOPE_BASE, "(objectClass=*)", ["namingContexts"]) {|e|
          e.get_values("namingContexts").each {|suffix|
            if (! @exclude.include?(suffix))
              if /#{org}/.match(suffix)
                result = get_servers(suffix, search_str)
                allresults.push result if result.length > 0
              end
            end
          }
        }
        rescue LDAP::ResultError
          conn.perror("LDAP connection failed")
          puts "LDAP connection failed"
        end  
    end
    allresults.push "\n"
    return allresults
  end
end
