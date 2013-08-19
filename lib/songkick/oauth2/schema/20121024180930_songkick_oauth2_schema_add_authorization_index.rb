class SongkickOauth2SchemaAddAuthorizationIndex < ActiveRecord::Migration
  INDEX_NAME = 'index_owner_client_pairs'

  def self.up
    remove_index :oauth2_authorizations, [:client_id, :access_token_hash]
    add_index :oauth2_authorizations, [:client_id, :oauth2_resource_owner_type, :oauth2_resource_owner_id], :name => INDEX_NAME, :unique => true
  end

  def self.down
    remove_index :oauth2_authorizations, :name => INDEX_NAME
    add_index :oauth2_authorizations, [:client_id, :access_token_hash]
  end
end

