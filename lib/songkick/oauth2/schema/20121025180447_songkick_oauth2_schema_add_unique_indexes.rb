class SongkickOauth2SchemaAddUniqueIndexes < ActiveRecord::Migration[6.1]
  def self.up
    remove_index :oauth2_authorizations, column: [:client_id, :code]
    remove_index :oauth2_authorizations, column: [:client_id, :refresh_token_hash], name: 'index_client_refresh'
    add_index :oauth2_authorizations, [:client_id, :code], :unique => true
    add_index :oauth2_authorizations, [:client_id, :refresh_token_hash], name: 'index_client_refresh', :unique => true
    remove_index :oauth2_authorizations, [:access_token_hash]
    add_index :oauth2_authorizations, [:access_token_hash], :unique => true

    remove_index :oauth2_clients, [:client_id]
    add_index :oauth2_clients, [:client_id], :unique => true

    add_index :oauth2_clients, [:name], :unique => true
  end

  def self.down
    FIELDS.each do |field|
      remove_index :oauth2_authorizations, [:client_id, field]
      add_index :oauth2_authorizations, [:client_id, field]
    end
    remove_index :oauth2_authorizations, [:access_token_hash]
    add_index :oauth2_authorizations, [:access_token_hash]

    remove_index :oauth2_clients, [:client_id]
    add_index :oauth2_clients, [:client_id]

    remove_index :oauth2_clients, [:name]
  end
end

