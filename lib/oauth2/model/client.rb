module OAuth2
  module Model
    
    class Client < ActiveRecord::Base
      set_table_name :oauth2_clients
      has_many :authorization_codes, :class_name => 'OAuth2::Model::AuthorizationCode', :dependent => :destroy
    end
    
  end
end

