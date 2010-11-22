require 'active_record'

module OAuth2
  module Model
    autoload :AuthorizationCode, 'oauth2/model/authorization_code'
    autoload :Client,     'oauth2/model/client'
    autoload :SCHEMA,     'oauth2/model/schema'
  end
end

