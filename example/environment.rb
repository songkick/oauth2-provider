dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'oauth2/provider'

require 'models/connection'
require 'models/user'
require 'models/note'

