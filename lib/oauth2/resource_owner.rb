module OAuth2
  module ResourceOwner
    
    def self.included(klass)
      klass.has_many :oauth2_authorizations,
                     :class_name => 'OAuth2::Model::Authorization',
                     :as => :oauth2_resource_owner
    end
    
    def grants_access?(access_token, *scopes)
      unless Model::Authorization === access_token
        access_token = oauth2_authorizations.find_by_access_token(access_token)
      end
      return false unless access_token
      access_token.grants_access?(self, *scopes)
    end
    
  end
end

