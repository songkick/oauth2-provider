module OAuth2
  module Model
    
    module BelongsToOwner
      def self.included(klass)
        klass.module_eval do
          belongs_to :oauth2_resource_owner, :polymorphic => true
          alias :owner  :oauth2_resource_owner
          alias :owner= :oauth2_resource_owner=
        end
      end
    end
    
  end
end

