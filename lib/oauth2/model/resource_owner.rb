module OAuth2
  module Model
    
    module AuthorizationAssociation
      def find_or_create_for_client(client)
        unless client.is_a?(Client)
          raise ArgumentError, "The argument should be a #{Client}, instead it was a #{client.class}"
        end
        
        # find_or_create_by_client_id does not work across AR versions
        authorization = find_by_client_id(client.id) || new
        authorization.client = client
        authorization.owner = owner
        authorization.save
        authorization
      end

    private

      def owner
        respond_to?(:proxy_association) ? proxy_association.owner : proxy_owner
      end
    end

    module ResourceOwner
      def self.included(klass)
        klass.has_many :oauth2_authorizations,
                       :class_name => 'OAuth2::Model::Authorization',
                       :as => :oauth2_resource_owner,
                       :dependent => :destroy,
                       :extend => AuthorizationAssociation
      end
      
      def grant_access!(client, options = {})
        authorization = oauth2_authorizations.find_or_create_for_client(client)

        if scopes = options[:scopes]
          scopes = authorization.scopes + scopes
          authorization.update_attribute(:scope, scopes.entries.join(' '))
        end
        
        authorization
      end
    end
    
  end
end
