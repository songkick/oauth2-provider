module OAuth2
  module Model
    
    class Authorization < ActiveRecord::Base
      set_table_name :oauth2_authorizations
      belongs_to :oauth2_resource_owner, :polymorphic => true
      belongs_to :client, :class_name => 'OAuth2::Model::Client'
      
      def owner
        oauth2_resource_owner
      end
      
      def expired?
        expires_at < Time.now
      end
      
      def in_scope?(request_scope)
        [*request_scope].all?(&scope_list.method(:include?))
      end
      
      def scope_list
        scope ? scope.split(/\s+/) : []
      end
    end
    
  end
end

