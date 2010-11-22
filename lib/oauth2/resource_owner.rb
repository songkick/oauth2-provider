module OAuth2
  module ResourceOwner
    
    def self.included(klass)
      klass.has_many :oauth2_authorizations, :as => :oauth2_resource_owner
    end
    
  end
end

