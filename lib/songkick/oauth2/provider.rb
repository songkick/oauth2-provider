require 'base64'
require 'bcrypt'
require 'cgi'
require 'digest/sha1'
require 'json'
require 'logger'
require 'rack'

begin
  require 'securerandom'
rescue LoadError
end

module Songkick
  module OAuth2
    ROOT = File.expand_path(File.dirname(__FILE__) + '/..')
    TOKEN_SIZE = 160

    autoload :Model,  ROOT + '/oauth2/model'
    autoload :Router, ROOT + '/oauth2/router'
    autoload :Schema, ROOT + '/oauth2/schema'

    def self.random_string
      if defined? SecureRandom
        SecureRandom.hex(TOKEN_SIZE / 8).to_i(16).to_s(36)
      else
        rand(2 ** TOKEN_SIZE).to_s(36)
      end
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
    AUTHORIZATION_CODE     = 'authorization_code'
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
    PASSWORD               = 'password'
    REDIRECT_URI           = 'redirect_uri'
    REFRESH_TOKEN          = 'refresh_token'
    RESPONSE_TYPE          = 'response_type'
    SCOPE                  = 'scope'
    STATE                  = 'state'
    TOKEN                  = 'token'
    USERNAME               = 'username'

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
      EXPIRY_TIME = 3600

      autoload :Authorization, ROOT + '/oauth2/provider/authorization'
      autoload :Exchange,      ROOT + '/oauth2/provider/exchange'
      autoload :AccessToken,   ROOT + '/oauth2/provider/access_token'
      autoload :Error,         ROOT + '/oauth2/provider/error'

      class << self
        attr_accessor :realm, :enforce_ssl
      end

      def self.clear_assertion_handlers!
        @password_handler   = nil
        @assertion_handlers = {}
        @assertion_filters  = []
      end

      clear_assertion_handlers!

      def self.handle_passwords(&block)
        @password_handler = block
      end

      def self.handle_password(client, username, password, scopes)
        return nil unless @password_handler
        @password_handler.call(client, username, password, scopes)
      end

      def self.filter_assertions(&filter)
        @assertion_filters.push(filter)
      end

      def self.handle_assertions(assertion_type, &handler)
        @assertion_handlers[assertion_type] = handler
      end

      def self.handle_assertion(client, assertion, scopes)
        return nil unless @assertion_filters.all? { |f| f.call(client) }
        handler = @assertion_handlers[assertion.type]
        handler ? handler.call(client, assertion.value, scopes) : nil
      end

      def self.parse(*args)
        Router.parse(*args)
      end

      def self.access_token(*args)
        Router.access_token(*args)
      end

      def self.access_token_from_request(*args)
        Router.access_token_from_request(*args)
      end
    end

  end
end

