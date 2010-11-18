module OAuth2
  module Model
    
    class Client < ActiveRecord::Base
      set_table_name :oauth2_clients
      has_many :access_codes, :class_name => 'OAuth2::Model::AccessCode', :dependent => :destroy
    end
    
  end
end

