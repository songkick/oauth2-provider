dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir)

require 'bundler'
Bundler.require

require 'oauth2/provider'
OAuth2::Provider.realm = 'Notes App'

require 'models/connection'
require 'models/user'
require 'models/note'

