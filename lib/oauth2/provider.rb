require 'uri'
require 'net/http'
require 'oauth2/rack'

module OAuth2
  ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
  
  autoload :Model,         ROOT + '/oauth2/model'
  autoload :SCHEMA,        ROOT + '/oauth2/provider/schema'
  autoload :ResourceOwner, ROOT + '/oauth2/resource_owner'
  
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
    
    autoload :Authorization, ROOT + '/oauth2/provider/authorization'
    autoload :Token,         ROOT + '/oauth2/provider/token'
    autoload :Error,         ROOT + '/oauth2/provider/error'
  end
end

