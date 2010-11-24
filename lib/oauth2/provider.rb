require 'uri'
require 'net/http'

module OAuth2
  ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
  TOKEN_SIZE = 128
  
  autoload :Model,         ROOT + '/oauth2/model'
  autoload :SCHEMA,        ROOT + '/oauth2/provider/schema'
  autoload :ResourceOwner, ROOT + '/oauth2/resource_owner'
  autoload :Rack,          ROOT + '/oauth2/rack'
  
  def self.random_string
    rand(2 ** TOKEN_SIZE).to_s(36)
  end
  
  def self.generate_id(&predicate)
    id = random_string
    id = random_string until predicate.call(id)
    id
  end
  
  class Provider
    INVALID_REQUEST        = 'invalid_request'
    UNSUPPORTED_RESPONSE   = 'unsupported_response_type'
    REDIRECT_MISMATCH      = 'redirect_uri_mismatch'
    UNSUPPORTED_GRANT_TYPE = 'unsupported_grant_type'
    INVALID_GRANT          = 'invalid_grant'
    INVALID_CLIENT         = 'invalid_client'
    INVALID_SCOPE          = 'invalid_scope'
    ACCESS_DENIED          = 'access_denied'
    
    EXPIRY_TIME          = 3600
    
    autoload :Authorization, ROOT + '/oauth2/provider/authorization'
    autoload :Token,         ROOT + '/oauth2/provider/token'
    autoload :Error,         ROOT + '/oauth2/provider/error'
    
    def self.parse(request)
      Rack.parse(request)
    end
  end
end

