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
    TempStore.get_accesspoints.to_json
  end

end
