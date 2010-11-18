require 'uri'
require 'net/http'
require 'oauth2/rack'

module OAuth2
  autoload :Model,  'oauth2/model'
  autoload :SCHEMA, 'oauth2/provider/schema'
  
  def self.random_string
    rand(2 ** 128).to_s(36)
  end
  
  class Provider
    autoload :Authorization, 'oauth2/provider/authorization'
  end
end

