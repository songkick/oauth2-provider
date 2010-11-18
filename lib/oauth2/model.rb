require 'active_record'

module OAuth2
  module Model
    autoload :AccessCode, 'oauth2/model/access_code'
    autoload :Client,     'oauth2/model/client'
    autoload :SCHEMA,     'oauth2/model/schema'
  end
end

