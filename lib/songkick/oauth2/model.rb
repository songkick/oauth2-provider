require 'active_record'

module Songkick
  module OAuth2
    module Model
      autoload :ClientOwner,   ROOT + '/oauth2/model/client_owner'
      autoload :ResourceOwner, ROOT + '/oauth2/model/resource_owner'
      autoload :Hashing,       ROOT + '/oauth2/model/hashing'
      autoload :Authorization, ROOT + '/oauth2/model/authorization'
      autoload :Client,        ROOT + '/oauth2/model/client'
      
      Schema = Songkick::OAuth2::Schema
      
      def self.find_access_token(access_token)
        return nil unless identifier = Provider.decrypt(access_token)
        Authorization.find_by_identifier(identifier)
      end
    end
  end
end

