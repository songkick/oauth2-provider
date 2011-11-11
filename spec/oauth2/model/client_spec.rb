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
  
  it "is invalid without a name" do
    @client.name = nil
    @client.should_not be_valid
  end
  
  it "is invalid without a redirect_uri" do
    @client.redirect_uri = nil
    @client.should_not be_valid
  end
  
  it "is invalid with a non-URI redirect_uri" do
    @client.redirect_uri = 'foo'
    @client.should_not be_valid
  end
  
  # http://en.wikipedia.org/wiki/HTTP_response_splitting
  it "is invalid if the URI contains HTTP line breaks" do
    @client.redirect_uri = "http://example.com/c\r\nb"
    @client.should_not be_valid
  end
  
  it "cannot mass-assign client_id" do
    @client.update_attributes(:client_id => 'foo')
    @client.client_id.should_not == 'foo'
  end
  
  it "cannot mass-assign client_secret" do
    @client.update_attributes(:client_secret => 'foo')
    @client.client_secret.should_not == 'foo'
  end
  
  it "has client_id and client_secret filled in" do
    @client.client_id.should_not be_nil
    @client.client_secret.should_not be_nil
  end
  
  it "destroys its authorizations on destroy" do
    @client.destroy
    OAuth2::Model::Authorization.count.should be_zero
  end

  it "does not allow client_id to be changed" do
    OAuth2::Model::Client.readonly_attributes.include?('client_id').should be_true
    expect{
      @client.client_id = 'foo'
      @client.save!
    }.to_not change{@client.reload.client_id}
  end
end

