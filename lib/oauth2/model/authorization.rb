module OAuth2
  module Model
    
    class Authorization < ActiveRecord::Base
      set_table_name :oauth2_authorizations
      belongs_to :oauth2_resource_owner, :polymorphic => true
      belongs_to :client, :class_name => 'OAuth2::Model::Client'
      
      validates_presence_of   :client
      validates_presence_of   :owner
      
      validates_uniqueness_of :code, :scope => :client_id, :allow_nil => true
      validates_uniqueness_of :refresh_token, :scope => :client_id, :allow_nil => true
      validates_uniqueness_of :access_token, :allow_nil => true
      
      alias :owner  :oauth2_resource_owner
      alias :owner= :oauth2_resource_owner=
      
      def self.create_code(client)
        code = OAuth2.random_string
        until client.authorizations.count(:conditions => {:code => code}).zero?
          code = OAuth2.random_string
        end
        code
      end
      
      def self.create_access_token
        token = OAuth2.random_string
        until count(:conditions => {:access_token => token}).zero?
          token = OAuth2.random_string
        end
        token
      end
      
      def self.create_refresh_token(client)
        refresh_token = OAuth2.random_string
        until client.authorizations.count(:conditions => {:refresh_token => refresh_token}).zero?
          refresh_token = OAuth2.random_string
        end
        refresh_token
      end
      
      def self.create_for_response_type(response_type, params = {})
        instance = new
        case response_type
          when 'code'
            instance.code = create_code(params[:client])
          when 'token'
            instance.access_token  = create_access_token
            instance.refresh_token = create_refresh_token(params[:client])
          when 'code_and_token'
            instance.code = create_code(params[:client])
            instance.access_token  = create_access_token
            instance.refresh_token = create_refresh_token(params[:client])
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
      
      def grants_access?(user, *scopes)
        not expired? and user == owner and in_scope?(scopes)
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
          :refresh_token => self.class.create_refresh_token(client),
          :expires_at    => Time.now + Provider::EXPIRY_TIME)
      end
    end
    
  end
end

