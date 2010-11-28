module OAuth2
  module Model
    
    class Authorization < ActiveRecord::Base
      set_table_name :oauth2_authorizations
      
      belongs_to :oauth2_resource_owner, :polymorphic => true
      belongs_to :client, :class_name => 'OAuth2::Model::Client'
      
      validates_presence_of :client, :owner
      
      validates_uniqueness_of :code,               :scope => :client_id, :allow_nil => true
      validates_uniqueness_of :refresh_token_hash, :scope => :client_id, :allow_nil => true
      validates_uniqueness_of :access_token_hash,                        :allow_nil => true
      
      alias :owner  :oauth2_resource_owner
      alias :owner= :oauth2_resource_owner=
      
      extend Hashing
      hashes_attributes :access_token, :refresh_token
      
      def self.for(resource_owner, client)
        return nil unless resource_owner and client
        
        find(:first, :conditions => {
          :oauth2_resource_owner_type => resource_owner.class.name,
          :oauth2_resource_owner_id   => resource_owner.id,
          :client_id                  => client.id
        })
      end
      
      def self.create_code(client)
        OAuth2.generate_id do |code|
          client.authorizations.count(:conditions => {:code => code}).zero?
        end
      end
      
      def self.create_access_token
        OAuth2.generate_id do |token|
          hash = OAuth2.hashify(token)
          count(:conditions => {:access_token_hash => hash}).zero?
        end
      end
      
      def self.create_refresh_token(client)
        OAuth2.generate_id do |refresh_token|
          hash = OAuth2.hashify(refresh_token)
          client.authorizations.count(:conditions => {:refresh_token_hash => hash}).zero?
        end
      end
      
      def self.for_response_type(response_type, params = {})
        instance = self.for(params[:owner], params[:client]) ||
                   new(:owner => params[:owner], :client => params[:client])
        
        case response_type
          when 'code'
            instance.code ||= create_code(params[:client])
          when 'token'
            instance.access_token  ||= create_access_token
            instance.refresh_token ||= create_refresh_token(params[:client])
          when 'code_and_token'
            instance.code = create_code(params[:client])
            instance.access_token  ||= create_access_token
            instance.refresh_token ||= create_refresh_token(params[:client])
        end
        
        if params[:duration]
          instance.expires_at = Time.now + params[:duration].to_i
        else
          instance.expires_at = nil
        end
        
        if params[:scope]
          scopes = instance.scopes + params[:scope].split(/\s+/)
          instance.scope = scopes.join(' ')
        end
        
        instance.save && instance
      end
      
      def exchange!
        self.code          = nil
        self.access_token  = self.class.create_access_token
        self.refresh_token = nil
        save!
      end
      
      def expired?
        return false unless expires_at
        expires_at < Time.now
      end
      
      def expires_in
        expires_at && (expires_at - Time.now).ceil
      end
      
      def generate_code
        self.code ||= self.class.create_code(client)
        save && code
      end
      
      def grants_access?(user, *scopes)
        not expired? and user == owner and in_scope?(scopes)
      end
      
      def in_scope?(request_scope)
        [*request_scope].all?(&scopes.method(:include?))
      end
      
      def scopes
        scope ? scope.split(/\s+/) : []
      end
    end
    
  end
end

