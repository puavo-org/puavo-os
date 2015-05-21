
# PuavoRestClient

CLI tool and Ruby library

## CLI

    Curl like client for puavo-rest

    Usage: puavo-rest-client [options] [SCHEME://HOST[:PORT]]<PATH>

    - If [SCHEME://HOST[:PORT]] is omitted it is automatically resolved from DNS
    - If DNS resolving fails a fallback is read from /etc/puavo/apiserver
    - If /etc/puavo/apiserver is not present puavo domain is used
    - Puavo domain is read from /etc/puavo/domain

    Examples:

    GET requests

    puavo-rest-client /v3/about
    puavo-rest-client https://api.puavo.org/v3/about
    puavo-rest-client --user-krb /v3/whoami
    puavo-rest-client --user-etc /v3/devices/laptop1
    puavo-rest-client --user uid=admin,o=puavo /v3/users
    puavo-rest-client --user uid=admin,o=puavo --domain other.opinsys.net --no-dns /v3/current_organisation

    POST requests

    puavo-rest-client --data current_image=the_running_image /v3/devices/laptop1
    puavo-rest-client --data-json '{"available_images": ["img1", "img2"]}' /v3/boot_servers/boot2

    Options:

    -u, --user <user[:password]>     Use basic auth. If password is not set password prompt will be displayed. Password is also read from the PUAVO_REST_CLIENT_PASSWORD env
        --user-etc                   Automatically load credendials from /etc/puavo/ldap
        --user-krb                   Use kerberos authentication
        --user-bootserver            Use bootserver authentication (aka no client authentication)
        --cacert FILE                Tells puavo-rest-client to use the specified certificate file to verify the peer
    -d, --data BODY                  Use POST method and use BODY as the request body using Content-type application/x-www-form-urlencoded.  Set - to read from standard input.
        --data-json JSON             POST JSON string with Content-Type application/json.  Set - to read from standard input.
    -H, --header HEADER              Add custom header. Can be set multiple times. Example: --header 'Content-Type: application/json'
        --domain DOMAIN              Use custom puavo domain. By default the domain is read from /etc/puavo/domain
        --no-dns                     Do not search for server from DNS
        --dns-only                   Force use server from DNS. If not found puavo-rest-client exits with a loud error
        --retry-fallback             When DNS resolving is used and the resolved server is unreachable retry the request using /etc/puavo/apiserver or puavo domain as the server
    -L, --location                   Follow location headers on 3XX status codes
        --port PORT                  Force custom port
        --scheme SCHEME              Force custom scheme (http or https)
    -m  --max-time SEC               Maximum time in seconds that you allow the whole operation to take
    -v, --verbose                    Be verbose. PUAVO_REST_CLIENT_VERBOSE=1 env can be also used
    -h, --help                       Show this message


## Ruby library

Single class is exposed.

```ruby
require "puavo/rest-client"

client = PuavoRestClient.new :auth => :kerberos
client.get("/v3/about")
```

The class constructor takes an options Hash with following keys (all optional):

- `:puavo_domain<String>` By default is read from /etc/puavo/domain
- `:dns<Symbol>` Set to `:no` to skip dns resolving or to `:only` to force dns usage
- `:server_host<String>: Use custom server host
- `:scheme<String>` Specify the protocol scheme. http or https
- `:ca_file<String>` Use the specified certificate file to verify the peer
- `:auth<Symbol>` Use the specific authentication method. `:etc`, `:kerberos` or `:bootserver`
- `:basic_auth<Hash>` Use custom basic auth: Example `{ :user => "username", :pass => "secret" }`
- `:headers<Hash>` Add custom headers
- `:location<Boolean>` Follow location header on 3XX status codes
- `:retry_fallback<Boolean>` When DNS resolving is used and the resolved server is unreachable retry the request using /etc/puavo/apiserver or puavo domain as the server
- `:port<FixNum>` Force custom port
- `:scheme<String>` Force scheme (http or https)
- `:timeout<Float>` Maximum time in seconds that you allow the whole operation to take


The value returned from the `get` method is a [http.rb] response object.

```ruby
res = client.get("/v3/whoami")

# Get parsed json
puts res.parse()["username"]
# => "alice"

# Raw response string
puts res.uri.to_s
# => "{\"dn\":\" ....

# http status code
puts res.code
# => 200

# Response headers
puts res.headers
# => #<HTTP::Headers {"Server"=>"nginx/1.1.19" ...

# requested uri
puts res.uri.to_s
# => "https://boot2.org.opinsys.net/v3/whoami"
```

`client.post(...)` can be used to issue POST requests

```ruby
client.post("/v3/boot_servers/laptop1", :json => {
    "available_images" => ["img1", "img2"]
})
```
The second argument is passed directly to http.rb's post method. See their
[docs](https://github.com/httprb/http.rb#post-requests).


[http.rb]: https://github.com/httprb/http.rb

