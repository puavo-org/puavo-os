#!/usr/bin/ruby
require 'sinatra/base'
require 'json'

class PuavoAPI < Sinatra::Base
  set :logging, false

  before do
    content_type :json
  end

  get '/users/organisation' do
    { "name"=>"example",
      "owners"=>[12],
      "preferred_language"=>nil,
      "puppet_host"=>"example.puppet.opinsys.fi",
      "domain"=>"www.example.com"}.to_json
  end

  get '/users/schools' do
    [ { "group_name" => "hosma",
        "postal_address" => "Example postal address",
        "name" => "Example school",
        "gid" => 10120,
        "postal_code" => "1234",
        "samba_group_type" => 2,
        "home_page" => "http://www.example.com",
        "samba_SID" => "",
        "street" => "Example street 5",
        "phone_number" => "12345678",
        "puavo_id" => 1,
        "post_office_box" => "PL 76309",
        "state" => nil } ].to_json
  end

  get '/users/groups' do
    [].to_json
  end

  Thread.new do
    run!
  end
end
