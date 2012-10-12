dir = File.expand_path('..', __FILE__)
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'songkick/oauth2/provider'
Songkick::OAuth2::Provider.realm = 'Notes App'
Songkick::OAuth2::Provider.secret = 'nbs8l93v7g0mzep6v2sokk730o75pxa'

require 'models/connection'
require 'models/user'
require 'models/note'

