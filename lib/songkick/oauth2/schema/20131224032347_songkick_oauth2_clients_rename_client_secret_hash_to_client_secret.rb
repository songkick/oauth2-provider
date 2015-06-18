class SongkickOauth2ClientsRenameClientSecretHashToClientSecret < ActiveRecord::Migration
  def self.up
    rename_column :oauth2_clients, :client_secret_hash, :client_secret
  end

  def self.down
    rename_column :oauth2_clients, :client_secret, :client_secret_hash
  end
end
