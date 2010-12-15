require 'active_record'

module OAuth2
  module Model
    autoload :BelongsToOwner,     ROOT + '/oauth2/model/belongs_to_owner'
    autoload :ClientOwner,        ROOT + '/oauth2/model/client_owner'
    autoload :AuthorizationOwner, ROOT + '/oauth2/model/authorization_owner'
    autoload :Hashing,            ROOT + '/oauth2/model/hashing'
    autoload :Authorization,      ROOT + '/oauth2/model/authorization'
    autoload :Client,             ROOT + '/oauth2/model/client'
    autoload :Schema,             ROOT + '/oauth2/model/schema'
  end
end

