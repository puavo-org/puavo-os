class SlapdConfig < ActiveLdap::Base
  ldap_mapping( :prefix => "",
                :classes => ['olcGlobal'] )
  
end
