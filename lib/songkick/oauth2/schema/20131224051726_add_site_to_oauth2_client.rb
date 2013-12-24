class AddSiteToOauth2Client < ActiveRecord::Migration
  def self.up
    add_column :oauth2_clients, :site, :string
  end

  def self.down
    remove_column :oauth2_clients, :site
  end
end
