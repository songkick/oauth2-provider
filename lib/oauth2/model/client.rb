module OAuth2
  module Model
    
    class Client < ActiveRecord::Base
      set_table_name :oauth2_clients
      has_many :authorizations, :class_name => 'OAuth2::Model::Authorization', :dependent => :destroy
      
      validates_uniqueness_of :client_id
      validates_presence_of   :name, :redirect_uri
      
      attr_accessible :name, :redirect_uri
      
      before_create :generate_credentials
      
      def self.create_client_id
        OAuth2.generate_id do |client_id|
          count(:conditions => {:client_id => client_id}).zero?
        end
      end
      
      def generate_credentials
        self.client_id = self.class.create_client_id
        self.client_secret = OAuth2.random_string
      end
    end
    
  end
end

