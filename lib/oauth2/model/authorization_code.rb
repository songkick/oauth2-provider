module OAuth2
  module Model
    
    class AuthorizationCode < ActiveRecord::Base
      set_table_name :oauth2_authorization_codes
      belongs_to :client, :class_name => 'OAuth2::Model::Client'
      
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

