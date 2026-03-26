# PuavoRestClient

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
- `:retry_fallback<Boolean>` When DNS resolving is used and the resolved server is unreachable retry the request using puavo api server
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
