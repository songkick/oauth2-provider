module OAuth2
  module Model
    
    SCHEMA = lambda do |version|
      create_table :oauth2_clients, :force => true do |t|
        t.timestamps
        t.string :client_id
        t.string :redirect_uri
      end
    end
    
  end
end

