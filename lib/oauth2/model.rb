require 'active_record'

module OAuth2
  module Model
    autoload :Authorization, 'oauth2/model/authorization'
    autoload :Client,     'oauth2/model/client'
    autoload :SCHEMA,     'oauth2/model/schema'
  end
end

