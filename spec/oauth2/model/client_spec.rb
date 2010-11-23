require 'spec_helper'

describe OAuth2::Model::Client do
  before do
    @client = OAuth2::Model::Client.create(:name => 'App', :redirect_uri => 'http://example.com/cb')
    @owner  = Factory(:owner)
    Factory(:authorization, :client => @client, :owner => @owner)
  end
  
  it "is valid" do
    @client.should be_valid
  end
  
  it "has client_id and client_secret filled in" do
    @client.client_id.should_not be_nil
    @client.client_secret.should_not be_nil
  end
  
  it "destroys its authorizations on destroy" do
    @client.destroy
    OAuth2::Model::Authorization.count.should be_zero
  end
end

