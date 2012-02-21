class LdapDn
  def initialize(dn_name=nil)
    tmp_dn_name = (dn_name ? "#{ dn_name }," : '')
    @dn_name    = "#{ tmp_dn_name }#{ $suffix }"
  end

  def dn(type=nil)
    typestring = (type ? ".#{ type }" : '')
    %Q|dn#{ typestring }="#{ @dn_name }"|
  end

  def children; dn('children'); end
  def exact   ; dn('exact')   ; end
  def onelevel; dn('onelevel'); end
  def subtree ; dn('subtree') ; end

  def self.children; new.children; end
  def self.exact   ; new.exact   ; end
  def self.onelevel; new.onelevel; end
  def self.subtree ; new.subtree ; end
end

class Automount < LdapDn
  def initialize
    @dn_name = "ou=Automount,#{ $suffix }"
  end
end

class Groups < LdapDn
  def initialize(subou='')
    @dn_name = "#{ subou }ou=Groups,#{ $suffix }"
  end

  def self.classes    ; new('ou=Classes,'    ); end
  def self.roles      ; new('ou=Roles,'      ); end
  def self.schoolroles; new('ou=SchoolRoles,'); end
  def self.schools    ; new('ou=Schools,'    ); end
end

class Hosts < LdapDn
  def initialize(subou='')
    @dn_name = "#{ subou }ou=Hosts,#{ $suffix }"
  end

  def self.devices; new('ou=Devices,'); end
  def self.samba  ; new('ou=Samba,'  ); end
  def self.servers; new('ou=Servers,'); end
end

class People < LdapDn
  def initialize
    @dn_name = "ou=People,#{ $suffix }"
  end
end

class Printers < LdapDn
  def initialize
    @dn_name = "ou=Printers,#{ $suffix }"
  end
end

class PuavoUid < LdapDn
  def initialize(uid)
    @dn_name = "uid=#{ uid },o=puavo"
  end

  # XXX why some are exact and some are not?
  def self.kadmin(method='exact'); new('kadmin' ).send(method); end	# XXX why sometimes .dn, sometimes .exact ?
  def self.kdc(method='exact')   ; new('kdc'    ).send(method); end	# XXX why sometimes .dn, sometimes .exact ?
  def self.monitor               ; new('monitor').dn          ; end
  def self.puavo(method='exact') ; new('puavo'  ).send(method); end	# XXX why sometimes .dn, sometimes .exact ?
  def self.puppet                ; new('puppet' ).dn          ; end
  def self.samba                 ; new('samba'  ).dn          ; end
  def self.slave                 ; new('slave'  ).exact       ; end
end

class Rule
  def self.none(*dn_list)
    perms('none', *dn_list)
  end

  def self.perms(mode, *dn_list)
    dn_list.flatten.map { |dn| self.string(dn, mode) }
  end

  def self.read(*dn_list)
    perms('read', *dn_list)
  end

  def self.string(dn, mode)
    %Q|by #{ dn } #{ mode }|
  end

  def self.write(*dn_list)
    perms('write', *dn_list)
  end
end

class RuleBreak < Rule
  def self.string(dn, mode); "#{ super } break"; end
end

class RuleContinue < Rule
  def self.string(dn, mode); "#{ super } continue"; end
end

class RuleStop < Rule
  def self.string(dn, mode); "#{ super } stop"; end
end

class Roles < LdapDn
  def initialize
    @dn_name = "ou=Roles,#{ $suffix }"
  end
end

class Samba < LdapDn
  def initialize
    @dn_name = "sambaDomainName=#{ $samba_domain },#{ $suffix }"
  end
end

class Set
  def self.admin
    [ org_owner, this_school_admin, ]
  end

  def self.all_admins
    [ school_admin, owner_and_user, ]
  end

  def self.getent
    [ People.children, Hosts.subtree, sysgroup('getent'), ]
  end

  def self.laptops
    # XXX should this be restricted to Devices-subtree?
    %Q|set="user/puavoDeviceType & [laptop]"|
  end

  def self.org_owner
    %Q|group/puavoEduOrg/owner=#{ $suffix }|
  end

  def self.owner_and_user
    %Q|set="[#{ $suffix }]/owner* & user"|
  end

  def self.puavoversion(number)
    %Q|set="[#{ $suffix }]/puavoVersion & [#{ number }]"|
  end

  def self.school_admin
    %Q|set="user/puavoAdminOfSchool*"|
  end

  def self.school_admin_and_user
    %Q|set="this/puavoSchoolAdmin* & user"|
  end

  def self.school_admin_or_owner_and_user
    %Q(set="this/puavoSchoolAdmin* | [#{ $suffix }]/owner* & user")
  end

  def self.syncrepl
    [ Hosts.servers.children, PuavoUid.slave, ]
  end

  def self.sysgroup(groupname)
    %Q|group/puavoSystemGroup/member="cn=#{ groupname },ou=System Groups,#{ $suffix }"|
  end

  def self.this_school_admin
    %Q|set="this/puavoSchool & user/puavoAdminOfSchool*"|
  end

  def self.teacher
    %Q|set="user/puavoEduPersonAffiliation & [teacher]"|
  end

  # self.sysgroups
  def self.addressbook  ; sysgroup('addressbook')  ; end
  def self.auth         ; sysgroup('auth')         ; end
  def self.devices      ; sysgroup('devices')      ; end
  def self.orginfo      ; sysgroup('orginfo')      ; end
  def self.printerqueues; sysgroup('printerqueues'); end
  def self.printers     ; sysgroup('printers')     ; end
  def self.servers      ; sysgroup('servers')      ; end
end

def attrs(attr_list)
  %Q|attrs="#{ Array(attr_list).join(',') }"|
end

def lines_with_index(lines)
  new_lines = []
  lines.each_with_index do |line, i|
    new_lines << "olcAccess: {#{ i }}to #{ line }\n"
  end
  new_lines
end

class LdapAcl
  def self.generate_acls(suffix, samba_domain)
    $samba_domain = samba_domain
    $suffix       = suffix

    lines_with_index(rules.map { |r| r.first.class == Array ? r : [ r ] } \
			  .flatten(1) \
			  .map { |a| a.join(' ') }) \
      .join('')
  end

  def self.rules
    [
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.onelevel,
	  'filter="(objectClass=posixGroup)"',														RuleStop.none(Set.puavoversion(2)),
																			RuleBreak.none('*'),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    [ Groups.schools, Groups.roles, Groups.schoolroles, Groups.classes, ].map do |subgroup|
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      [ subgroup.subtree,																RuleBreak.none(Set.puavoversion(2)),	]
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    end,

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.samba.subtree,						Rule.write(Hosts.servers.children),						RuleBreak.none('*'),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(sambaNTPassword
					 userPassword
					 sambaAcctFlags)),		Rule.write(Hosts.servers.children),						RuleBreak.none('*'), 			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Samba.exact,							Rule.write(Hosts.servers.children),						RuleBreak.none('*'), 			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Printers.exact,		attrs(%w(ou
					 entry
					 objectClass)),								Rule.read(Set.syncrepl,
															  Set.owner_and_user,
															  People.children,
															  Set.printerqueues),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Printers.exact,		attrs(%w(children)),			Rule.write(Set.owner_and_user,
										   Hosts.servers.children),	Rule.read(People.children,
															  PuavoUid.slave,
															  Set.printerqueues),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Printers.children,						Rule.write(Set.owner_and_user,
										   Hosts.servers.children),	Rule.read(People.children,
															  PuavoUid.slave,
															  Set.printerqueues),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new.subtree,											Rule.read(Set.syncrepl),		RuleBreak.none('*'),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.exact,		attrs(%w(entry
				      ou
				      objectClass)),								Rule.read(Set.getent,
															  Set.auth,
															  PuavoUid.puavo),		Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.exact,		attrs(%w(children)),			Rule.write(Set.all_admins),		Rule.read(PuavoUid.puavo),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(puavoAdminOfSchool)),		Rule.write(Set.owner_and_user),		Rule.read('users'),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(userPassword)),
	  'filter="(puavoEduPersonAffiliation=student)"',												Rule.perms('=azx', Set.all_admins,
																					   Set.teacher),
																			RuleBreak.none('*'),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(userPassword)),
	  'filter="(puavoLocked=TRUE)"',														Rule.perms('=azx', Set.admin,
																					   'self'),		],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(userPassword)),												Rule.perms('=azx', Set.admin,
																					   'self'),
																			Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(shadowLastChange)),
	  'filter="(puavoEduPersonAffiliation=student)"',		Rule.write(Set.all_admins),							RuleBreak.none('*'),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(shadowLastChange)),		Rule.write(Set.admin,
										   'self'),								Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(entry
					 uid
					 puavoId
					 eduPersonPrincipalName
					 objectClass
					 puavoEduPersonAffiliation)),	Rule.write(Set.admin),			Rule.read(PuavoUid.puavo('dn'),
															  Set.getent,
															  Set.auth),			Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(uidNumber
					 gidNumber
					 homeDirectory
					 givenName
					 sn
					 preferredLanguage
					 puavoPreferredDesktop)),	Rule.write(Set.admin),			Rule.read(Set.getent,
															  PuavoUid.puavo('dn')),						],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(givenName
					 sn
					 displayName
					 puavoEduPersonReverseDisplayName)),
									Rule.write(Set.admin),			Rule.read(People.children,
															  Hosts.subtree,
															  Set.sysgroup('getent'),
															  Set.addressbook),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(puavoEduPersonPersonnelNumber)),
									Rule.write(Set.admin),			Rule.read(Set.addressbook),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(mail
					 telephoneNumber)),		Rule.write(Set.admin,
										   'self'),			Rule.read(Set.addressbook),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
																			# XXX odd
      [ People.subtree,		attrs(%w(puavoAcceptedTerms)),		Rule.write(Set.admin),			Rule.read(PuavoUid.puavo),		Rule.write('self'),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(puavoSchool)),			Rule.write(Set.admin),			Rule.read('self'),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,		attrs(%w(sambaNTPassword
					 sambaLMPassword)),												Rule.perms('=az', Set.admin),		],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ People.subtree,							Rule.write(Set.admin),			Rule.read(Hosts.subtree),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Roles.exact,		attrs(%w(entry
					 ou
					 objectClass)),								Rule.read(Set.all_admins),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Roles.exact,		attrs(%w(children)),			Rule.write(Set.all_admins),												],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Roles.children,							Rule.write(Set.admin),													],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Automount.exact,	attrs(%w(entry
					 ou
					 objectClass)),								Rule.read('*'),									],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Automount.exact,	attrs(%w(children)),			Rule.write(Set.owner_and_user),		Rule.read('*'),									],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Automount.children,						Rule.write(Set.owner_and_user),		Rule.read('*'),									],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new('ou=Kerberos Realms').subtree,			Rule.write(PuavoUid.kadmin('dn')),	Rule.read(PuavoUid.kdc('dn')),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.exact,												Rule.read(Set.all_admins,
															  PuavoUid.puppet,
															  PuavoUid.monitor),
														'by',				# XXX this is most probably a bug, does it have any implications?
														Rule.read(Set.devices,
															  Set.servers,
															  People.children),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.devices.exact,	attrs(%w(entry
					 ou
					 objectClass)),								Rule.read(Set.all_admins,
															  PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.devices,
															  People.children),       	Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.devices.exact,	attrs(%w(children)),			Rule.write(Set.all_admins),		Rule.read(PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.devices,
															  People.children),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.devices.children,	attrs(%w(entry
					 objectClass
					 puavoHostname
					 puavoTag)),			Rule.write(Set.admin),			Rule.read(PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.devices,
															  People.children),		Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.devices.children,						Rule.write(Set.admin),			Rule.read(PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.devices),			Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.servers.exact,	attrs(%w(entry
					 ou
					 objectClass)),								Rule.read(Set.owner_and_user,
															  PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.servers),			Rule.perms('auth', 'anonymous'),	],
# -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.servers.exact,	attrs(%w(children)),			Rule.write(Set.owner_and_user),		Rule.read(PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.servers),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.servers.children,						Rule.write(Set.owner_and_user),		Rule.read(PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.servers),
														RuleBreak.none(Set.laptops),		Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.servers.children,	attrs(%w(entry
					 ou
					 objectClass
					 puavoExport
					 puavoHostname)),							Rule.read(Set.laptops),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.samba.exact,	attrs(%w(entry
					 ou
					 objectClass)),								Rule.read(Hosts.servers.children),						],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.samba.exact,	attrs(%w(children)),			Rule.write(Hosts.servers.children),											],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Hosts.samba.children,						Rule.write(Hosts.servers.children),											],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.new('cn=Domain Admins,').exact,
				attrs(%w(memberUid)),			Rule.write(Set.owner_and_user),												],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.new('cn=Domain Users,').exact,
				attrs(%w(memberUid)),			Rule.write(Set.all_admins),												],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.new('cn=Domain Admins,').exact,									Rule.read(Set.owner_and_user),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.new('cn=Domain Users,').exact,									Rule.read(Set.all_admins),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.exact,		attrs(%w(entry
					 ou
					 objectClass)),								Rule.read(Set.all_admins,
															  Set.getent),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.exact,		attrs(%w(children)),			Rule.write(Set.all_admins),		Rule.read(Set.getent),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    %w(schools roles schoolroles classes).map do |subgroup_method|
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
      subgroup = Groups.send(subgroup_method)

      [[ subgroup.exact,	attrs(%w(entry
					 ou
					 objectClass)),								Rule.read(Set.all_admins,
															  Set.getent),								],
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       [ subgroup.exact,	attrs(%w(children)),			Rule.write(Set.all_admins),		Rule.read(Set.getent),								],
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       # XXX is this a bug?  why are 'Schools' an exception?
       (subgroup_method == 'schools' \
          ? nil \
          : [ subgroup.subtree,	attrs(%w(member
					 memberUid)),			Rule.write(Set.admin),			Rule.read(Set.getent),								]),
# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
       [ subgroup.subtree,						Rule.write(
									  subgroup_method == 'classes' \
									    ? Set.admin \
									    : Set.owner_and_user),		Rule.read(Set.getent),								]]

    end.flatten(1).compact,

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.subtree,
	 'filter=(objectClass=puavoEduGroup)',
				attrs(%w(gidNumber
					 cn
					 puavoId
					 objectClass)),			Rule.write(Set.admin),			Rule.read(Set.getent),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.subtree,
	 'filter=(objectClass=puavoSchool)',
				attrs(%w(gidNumber
					 cn
					 puavoId
					 objectClass)),													Rule.perms('+azrwsc', Set.owner_and_user),
																			Rule.perms('+rwsc',   Set.school_admin_and_user),
																			Rule.read(People.children, Hosts.subtree),
																			RuleBreak.read(Set.sysgroup('getent')), ],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.subtree,
	  'filter=(objectClass=puavoEduGroup)',				Rule.write(Set.admin),			Rule.read(Set.getent),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.subtree,
	  'filter=(objectClass=puavoSchool)',
				attrs(%w(member
					 memberUid)),			Rule.write(Set.school_admin_or_owner_and_user),
														Rule.read(People.children, Hosts.subtree),
														RuleBreak.read(Set.sysgroup('getent')),						],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Groups.subtree,
	  'filter=(objectClass=puavoSchool)',				Rule.write(Set.owner_and_user),							Rule.perms('+rscxd', Set.school_admin_and_user),
																			Rule.read(Set.getent),			],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Samba.exact,		attrs(%w(sambaSID
					 sambaDomainName
					 sambaNextUserRid
					 sambaNextRid)),		Rule.write(PuavoUid.samba,
										   Set.all_admins),												],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ Samba.exact,							Rule.write(Set.admin,
										   PuavoUid.samba),		Rule.read(Set.all_admins),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new('ou=System Accounts').subtree,
				attrs(%w(userPassword)),		Rule.write(Set.admin),								Rule.perms('auth', 'anonymous'),	],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new('ou=System Accounts').subtree,			Rule.write(Set.admin),			Rule.read(PuavoUid.puavo),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new('ou=System Groups'  ).subtree,
				attrs(%w(member)),			Rule.write(Set.admin),													],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new('ou=System Groups'  ).subtree,								Rule.read(Set.admin),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new('ou=Desktops'       ).subtree,			Rule.write(Set.owner_and_user),		Rule.read(People.children),							],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new.dn,		attrs(%w(entry)),								Rule.read(Set.all_admins,
															  PuavoUid.puavo,
															  PuavoUid.kdc,
															  PuavoUid.kadmin,
															  PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.getent,
															  Set.orginfo),			Rule.perms('+sxd', '*'),		],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new.dn,		attrs(%w(objectClass)),								Rule.read(Set.all_admins,
															  PuavoUid.puavo,
															  PuavoUid.kdc,
															  PuavoUid.kadmin,
															  PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.getent,
															  Set.orginfo),			Rule.perms('+sxd', '*'),		],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new.dn,		attrs(%w(puavoEduOrgAbbreviation
					 st
					 l
					 street
					 postalCode
					 postalAddress
					 telephoneNumber
					 postOfficeBox
					 facsimileTelephoneNumber
					 description
					 preferredLanguage
					 eduOrgLegalName
					 o
					 eduOrgHomePageURI
					 puavoDeviceOnHour
					 puavoDeviceOffHour
					 puavoDeviceAutoPowerOffMode)),	Rule.write(Set.owner_and_user),		Rule.read(Set.all_admins,
															  PuavoUid.puavo,
															  PuavoUid.kdc,
															  PuavoUid.kadmin,
															  PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.getent,
															  Set.orginfo),			Rule.perms('+sxd', '*'),		],

# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new.dn,		attrs(%w(owner
					 puavoDomain
					 puavoPuppetHost)),							Rule.read(Set.all_admins,
															  PuavoUid.puavo,
															  PuavoUid.puppet,
															  PuavoUid.monitor,
															  Set.orginfo),								],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
      [ LdapDn.new.dn,												Rule.read(Set.all_admins,
															  PuavoUid.puavo,
															  PuavoUid.kdc,
															  PuavoUid.kadmin,
															  PuavoUid.puppet,
															  PuavoUid.monitor),		Rule.perms('+sxd', '*'),		],
# --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    ]
  end
end
