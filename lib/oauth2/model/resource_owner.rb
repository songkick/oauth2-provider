module OAuth2
  module Model
    
    module ResourceOwner
      def self.included(klass)
        klass.has_many :oauth2_authorizations,
                       :class_name => 'OAuth2::Model::Authorization',
                       :as => :oauth2_resource_owner,
                       :dependent => :destroy
      end
      
      def grant_access!(client, options = {})
        authorization = oauth2_authorizations.find_or_create_for_client(client)

        if scopes = options[:scopes]
          scopes = authorization.scopes + scopes
          authorization.update_scope(scopes.entries.join(' '))
        end
        
        authorization
      end
    end
    
  end
end
