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
          Authorization.for(self, client, options)
        end

        def oauth2_authorization_for(client)
          oauth2_authorizations.find_by_client_id(client.id)
        end
      end

    end
  end
end
