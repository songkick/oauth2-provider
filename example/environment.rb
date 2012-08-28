dir = File.expand_path('..', __FILE__)
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'songkick/oauth2/provider'
Songkick::OAuth2::Provider.realm = 'Notes App'

require 'models/connection'
require 'models/user'
require 'models/note'

