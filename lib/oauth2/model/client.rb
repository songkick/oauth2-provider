module OAuth2
  module Model
    
    class Client < ActiveRecord::Base
      set_table_name :oauth2_clients
      has_many :authorizations, :class_name => 'OAuth2::Model::Authorization', :dependent => :destroy
    end
    
  end
end

