
# Development installation

This is pretty messed up. Really.

Install [puavo-standalone](https://github.com/opinsys/puavo-standalone/) on a Ubuntu Precise machine.

Create another machine for Iivari with Ubuntu Lucid.

For example with LXC

    lxc-create -n iivari -t ubuntu -- --release lucid --arch amd64

> If it does not boot try removing symlink `/dev/shm` from the container

Add `iivari` ldap service with password `passwordpassword` from the puavo-web `http://<ip>:8081/users/ldap_services`

Continue on the Lucid machine.

## Configure LDAP connection

Copy ldap certificate from the puavo-standalone

    scp $PUAVO_STANDALONE_IP:/etc/ssl/certs/slapd-ca.crt .
    sudo install -D -o root -g root -m 644 slapd-ca.crt /etc/ssl/certs/opinsys-ca.crt
    rm slapd-ca.crt

Where `$PUAVO_STANDALONE_IP` is the ip address of the puavo-standalone server

Set `/etc/ldap/ldap.conf` to

```
TLS_CACERT      /etc/ssl/certs/opinsys-ca.crt
TLS_REQCERT     demand
```

Set fqdn on for the puavo-standalone server

    echo "$PUAVO_STANDALONE_IP $PUAVO_STANDALONE_FQDN" >> /etc/hosts

> You can get the value of the `$PUAVO_STANDALONE_FQDN` variable on the puavo-standalone machine with `hostname -f`

Test the connection

    ldapsearch -H ldap://$PUAVO_STANDALONE_FQDN -x -D uid=puavo,o=puavo -w password -Z -b o=Puavo "(cn=IdPool)"

## Install Iivari

Install ruby and other build deps

    sudo apt-get install ruby libopenssl-ruby1.8 irb libxslt-dev ruby-dev libpq-dev libmagickcore-dev libmagickwand-dev libldap2-dev libssl-dev libsasl2-dev libsqlite3-dev ldap-utils

Install rubygems and bundler

    wget http://production.cf.rubygems.org/rubygems/rubygems-1.3.7.tgz
    tar zxf rubygems-1.3.7.tgz
    cd rubygems-1.3.7
    sudo ruby setup.rb
    sudo gem1.8 install bundler

> Lucid has rubygems 1.3.6 in the repositories but bundler requires at least 1.3.7.

Get the source code

    git clone https://github.com/opinsys/iivari
    cd iivari/server/

Install gems

    bundle install --deployment

Add database config

    cp config/database.yml.example config/database.yml

Add `config/organisations.yml`

```yaml
hogwarts:
  name: Hogwarts
  host: $IIVARI_IP
  ldap_host: $PUAVO_STANDALONE_FQDN
  ldap_base: dc=edu,dc=hogwarts,dc=fi
  uid_search_dn: uid=puavo,o=puavo
  uid_search_password: password
  # fi/en
  locale: fi
  # none/tls
  ldap_method: tls
  # The number of seconds between update checks (data of slides)
  data_update_interval: 60
  puavo_api_ssl: false
  puavo_api_server: $PUAVO_STANDALONE_FQDN:8081
  puavo_api_username: service/iivari
  puavo_api_password: passwordpassword
```

Replace `$IIVARI_IP` and `$PUAVO_STANDALONE_FQDN` with proper hostnames or IPs

Run database migrations

    bundle exec rake db:migrate

Start Iivari server

    bundle exec rails server

Login on `http://$IIVARI_IP:3000`

Profit?
