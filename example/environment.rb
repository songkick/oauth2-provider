dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'oauth2/provider'
OAuth2::Provider.realm = 'Notes App'
OAuth2::Provider.mode  = 'development'

require 'models/connection'
require 'models/user'
require 'models/note'

