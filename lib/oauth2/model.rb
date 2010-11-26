require 'active_record'

module OAuth2
  module Model
    autoload :Hashing,       ROOT + '/oauth2/model/hashing'
    autoload :Authorization, ROOT + '/oauth2/model/authorization'
    autoload :Client,        ROOT + '/oauth2/model/client'
    autoload :Schema,        ROOT + '/oauth2/model/schema'
  end
end

