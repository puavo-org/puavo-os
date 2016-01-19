
# Require rbconfig for 1.8 ruby
require "rbconfig"

require 'puavo/gems'

require 'httparty'
require 'json'

require 'puavo/etc'
require 'puavo/execute'
require 'puavo/client/base'
require 'puavo/client/api/base'
require 'puavo/client/api/schools'
require 'puavo/client/api/groups'
require 'puavo/client/api/devices'
require 'puavo/client/api/users'
require 'puavo/client/api/organisation'
require 'puavo/client/api/servers'
require 'puavo/client/api/external_files'

require 'puavo/client/hash_mixin/base'
require 'puavo/client/hash_mixin/device_base'
require 'puavo/client/hash_mixin/device'
require 'puavo/client/hash_mixin/organisation'
require 'puavo/client/hash_mixin/school'
require 'puavo/client/hash_mixin/server'
require 'puavo/client/hash_mixin/external_file'

require 'puavo/client/model'
require 'puavo/client/school'
require 'puavo/client/group'
require 'puavo/client/device'
require 'puavo/client/user'
require 'puavo/client/organisation'
require 'puavo/client/server'
require 'puavo/client/external_file'
