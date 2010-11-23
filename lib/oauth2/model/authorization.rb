module OAuth2
  module Model
    
    class Authorization < ActiveRecord::Base
      set_table_name :oauth2_authorizations
      belongs_to :oauth2_resource_owner, :polymorphic => true
      belongs_to :client, :class_name => 'OAuth2::Model::Client'
      
      validates_presence_of   :client
      validates_presence_of   :owner
      validates_uniqueness_of :access_token, :allow_nil => true
      
      alias :owner  :oauth2_resource_owner
      alias :owner= :oauth2_resource_owner=
      
      def self.create_access_token
        token = OAuth2.random_string
        token = OAuth2.random_string until count(:conditions => {:access_token => token}).zero?
        token
      end
      
      def self.create_for_response_type(response_type, params = {})
        instance = new
        case response_type
          when 'code'
            instance.code = OAuth2.random_string
          when 'token'
            instance.access_token  = OAuth2.random_string
            instance.refresh_token = OAuth2.random_string
          when 'code_and_token'
            instance.code = OAuth2.random_string
            instance.access_token  = OAuth2.random_string
            instance.refresh_token = OAuth2.random_string
        end
        
        instance.expires_at = Time.now + Provider::EXPIRY_TIME
        
        params.each do |key, value|
          instance.__send__("#{key}=", value)
        end
        
        instance.save && instance
      end
      
      def expired?
        return false unless expires_at
        expires_at < Time.now
      end
      
      def expires_in
        (expires_at - Time.now).ceil
      end
      
      def grants_access?(user, *scope)
        not expired? and user == owner and in_scope?(scope)
      end
      
      def in_scope?(request_scope)
        [*request_scope].all?(&scope_list.method(:include?))
      end
      
      def scope_list
        scope ? scope.split(/\s+/) : []
      end
      
      def update_tokens
        update_attributes(
          :code          => nil,
          :access_token  => self.class.create_access_token,
          :refresh_token => OAuth2.random_string,
          :expires_at    => Time.now + Provider::EXPIRY_TIME)
      end
    end
    
  end
end

