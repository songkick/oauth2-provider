require 'uri'
require 'net/http'
require 'oauth2/rack'

module OAuth2
  autoload :Model,         'oauth2/model'
  autoload :SCHEMA,        'oauth2/provider/schema'
  autoload :ResourceOwner, 'oauth2/resource_owner'
  
  def self.random_string
    rand(2 ** 128).to_s(36)
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
    
    autoload :Authorization, 'oauth2/provider/authorization'
    autoload :Token,         'oauth2/provider/token'
    autoload :Error,         'oauth2/provider/error'
  end
end

