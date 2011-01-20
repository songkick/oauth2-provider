require 'cgi'
require 'digest/sha1'
require 'bcrypt'
require 'json'
require 'active_record'

module OAuth2
  ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
  TOKEN_SIZE = 128
  
  autoload :Model,  ROOT + '/oauth2/model'
  autoload :Router, ROOT + '/oauth2/router'
  
  def self.random_string
    rand(2 ** TOKEN_SIZE).to_s(36)
  end
  
  def self.generate_id(&predicate)
    id = random_string
    id = random_string until predicate.call(id)
    id
  end
  
  def self.hashify(token)
    return nil unless String === token
    Digest::SHA1.hexdigest(token)
  end
  
  ACCESS_TOKEN           = 'access_token'
  ASSERTION              = 'assertion'
  ASSERTION_TYPE         = 'assertion_type'
  CLIENT_ID              = 'client_id'
  CLIENT_SECRET          = 'client_secret'
  CODE                   = 'code'
  CODE_AND_TOKEN         = 'code_and_token'
  DURATION               = 'duration'
  ERROR                  = 'error'
  ERROR_DESCRIPTION      = 'error_description'
  EXPIRES_IN             = 'expires_in'
  GRANT_TYPE             = 'grant_type'
  OAUTH_TOKEN            = 'oauth_token'
  REDIRECT_URI           = 'redirect_uri'
  REFRESH_TOKEN          = 'refresh_token'
  RESPONSE_TYPE          = 'response_type'
  SCOPE                  = 'scope'
  STATE                  = 'state'
  TOKEN                  = 'token'
  
  INVALID_REQUEST        = 'invalid_request'
  UNSUPPORTED_RESPONSE   = 'unsupported_response_type'
  REDIRECT_MISMATCH      = 'redirect_uri_mismatch'
  UNSUPPORTED_GRANT_TYPE = 'unsupported_grant_type'
  INVALID_GRANT          = 'invalid_grant'
  INVALID_CLIENT         = 'invalid_client'
  UNAUTHORIZED_CLIENT    = 'unauthorized_client'
  INVALID_SCOPE          = 'invalid_scope'
  INVALID_TOKEN          = 'invalid_token'
  EXPIRED_TOKEN          = 'expired_token'
  INSUFFICIENT_SCOPE     = 'insufficient_scope'
  ACCESS_DENIED          = 'access_denied'
  
  class Provider
    VERSION = '0.1.0'
    
    class << self
      attr_accessor :realm, :mode
    end
    
    MODE_DEVELOPMENT = 'development'
    MODE_PRODUCTION  = 'production'
    
    self.mode = MODE_PRODUCTION
    
    def self.clear_assertion_handlers!
      @assertion_handlers = {}
      @assertion_filters  = []
    end
    
    clear_assertion_handlers!
    
    def self.filter_assertions(&filter)
      @assertion_filters.push(filter)
    end
    
    def self.handle_assertions(assertion_type, &handler)
      @assertion_handlers[assertion_type] = handler
    end
    
    def self.handle_assertion(client, assertion)
      return nil unless @assertion_filters.all? { |f| f.call(client) }
      handler = @assertion_handlers[assertion.type]
      handler ? handler.call(client, assertion.value) : nil
    end
    
    def self.parse(*args)
      Router.parse(*args)
    end
    
    def self.access_token(*args)
      Router.access_token(*args)
    end
    
    EXPIRY_TIME            = 3600
    
    autoload :Authorization, ROOT + '/oauth2/provider/authorization'
    autoload :Exchange,      ROOT + '/oauth2/provider/exchange'
    autoload :AccessToken,   ROOT + '/oauth2/provider/access_token'
    autoload :Error,         ROOT + '/oauth2/provider/error'
  end
end

