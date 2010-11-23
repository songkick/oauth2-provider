module OAuth2
  module Model
    
    class Client < ActiveRecord::Base
      set_table_name :oauth2_clients
      has_many :authorizations, :class_name => 'OAuth2::Model::Authorization', :dependent => :destroy
      
      validates_uniqueness_of :client_id
      
      before_create :generate_credentials
      
      def self.create_client_id
        client_id = OAuth2.random_string
        until count(:conditions => {:client_id => client_id}).zero?
          client_id = OAuth2.random_string
        end
        client_id
      end
      
      def generate_credentials
        self.client_id = self.class.create_client_id
        self.client_secret = OAuth2.random_string
      end
    end
    
  end
end

