#!/usr/bin/env ruby1.9.1

require 'json'
require 'sinatra'

require_relative './permstore.rb'
require_relative './tempstore.rb'

class Controller < Sinatra::Base

  before do
    content_type 'application/json'
  end

  put '/v1/report/:name/:host' do
    data = request.body.read
    json = data.empty? ? {}.to_json : JSON.parse(data).to_json
    host = params[:host]
    name = params[:name]
    PermStore.add_report(name, host, json)
    TempStore.add_accesspoint(host)
  end

  get '/v1/status' do
    accesspoints = TempStore.get_accesspoints

    case request.preferred_type.entry
    when 'application/json'
      accesspoints.to_json
    when 'text/html'
      content_type 'text/html'
      ERB.new(<<'EOF'
<!doctype html>
<html>
  <head>
    <meta charset="utf-8">
    <title>Puavo's WLAN Controller - Status</title>
  </head
  <body>
    <h1>Status</h1>
    <ul><% accesspoints.each do |ap| %>
        <li><%= ap %></li><% end %>
    </ul>
  </body>
</html>
EOF
              ).result(binding)
    else
      content_type 'text/plain'
      accesspoints.join('\n')
    end
  end

end
