
# Insert dependency paths from `bundle install --standalone --path ...`.
# See Makefile
require File.expand_path(File.dirname(__FILE__) + "/puavo-client-vendor/bundler/setup.rb")

require 'httparty'
require 'json'

require 'puavo/client/base'
require 'puavo/client/api/base'
require 'puavo/client/api/schools'
require 'puavo/client/api/groups'
require 'puavo/client/api/devices'
require 'puavo/client/api/users'
require 'puavo/client/api/organisation'

require 'puavo/client/model'
require 'puavo/client/school'
require 'puavo/client/group'
require 'puavo/client/device'
require 'puavo/client/user'
require 'puavo/client/organisation'
