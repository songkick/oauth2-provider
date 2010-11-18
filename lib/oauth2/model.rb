require 'active_record'

module OAuth2
  module Model
    autoload :Client, 'oauth2/model/client'
    autoload :SCHEMA, 'oauth2/model/schema'
  end
end

