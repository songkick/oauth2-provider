dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'oauth2/provider'
OAuth2.realm = 'Notes App'

require 'models/connection'
require 'models/user'
require 'models/note'

