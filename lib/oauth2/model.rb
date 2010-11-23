require 'active_record'

module OAuth2
  module Model
    autoload :Authorization, ROOT + '/oauth2/model/authorization'
    autoload :Client,        ROOT + '/oauth2/model/client'
    autoload :SCHEMA,        ROOT + '/oauth2/model/schema'
  end
end

