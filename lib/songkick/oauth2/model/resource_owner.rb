module Songkick
  module OAuth2
    module Model
      
      module ResourceOwner
        def self.included(klass)
          klass.has_many :oauth2_authorizations,
                         :class_name => Authorization.name,
                         :as => :oauth2_resource_owner,
                         :dependent => :destroy
        end
        
        def grant_access!(client, options = {})
          options = {:owner => self, :client => client}.merge(options)
          Authorization.for_response_type(nil, options)
        end
      end
      
    end
  end
end
