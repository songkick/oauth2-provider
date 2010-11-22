module OAuth2
  module Model
    
    SCHEMA = lambda do |version|
      create_table :oauth2_clients, :force => true do |t|
        t.timestamps
        t.string :name
        t.string :client_id
        t.string :client_secret
        t.string :redirect_uri
      end
      
      create_table :oauth2_access_codes, :force => true do |t|
        t.timestamps
        t.belongs_to :client
        t.string     :code
        t.datetime   :expires_at
      end
    end
    
  end
end

