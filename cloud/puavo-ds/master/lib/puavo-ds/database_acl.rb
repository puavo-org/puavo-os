require 'open3'

class LdapAcl
  def self.generate_acls(suffix, kerberos_realm, samba_domain)
    acls, stderr_str, status \
      = Open3.capture3('puavo-print-acls', suffix, kerberos_realm, samba_domain)
    unless status.success? then
      errmsg = "puavo-print-acls returned status code #{ status.exitstatus }" \
                 + " with the following errors:\n#{ stderr_str }"
      raise errmsg
    end

    acls.split("\n")
  end
end
