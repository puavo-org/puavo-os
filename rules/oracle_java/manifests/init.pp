class oracle_java {
  include ::oracle_java::no_revocation_check
  include ::oracle_java::tools
  include ::puavo_pkg::packages

  Puavo_pkg::Install <| title == 'oracle-java' |> {
     require +> [ File['/opt/java/opinsys-add-cert']
		, File['/opt/java/opinsys-create-signed-ruleset'] ]
  }
}
