#!/usr/bin/ruby

require 'sinatra'
require 'LocateUser'

get '/locateuser' do
   content_type :text
   locateuser = LocateUser.new
   return locateuser.query(params[:org], params[:q]).join("\n")
end

