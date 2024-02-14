require 'spec_helper'

describe Songkick::OAuth2::Model::Client do
  before do
    @client = Songkick::OAuth2::Model::Client.create(:name => 'App', :redirect_uri => 'http://example.com/cb')
    @owner  = FactoryBot.create(:owner)
    Songkick::OAuth2::Model::Authorization.for(@owner, @client)
  end

  it "is valid" do
    expect(@client).to be_valid
  end

  it "is invalid without a name" do
    @client.name = nil
    expect(@client).to_not be_valid
  end

  it "gives an appropriate message for an invalid uri" do
    @client.redirect_uri = "http://underscore_uri_not_valid/receive_token"
    @client.should_not be_valid
    @client.errors[:redirect_uri].first.should eq("must be a URI: the scheme http does not accept registry part: underscore_uri_not_valid (or bad hostname?)")
  end

  it "is invalid without a redirect_uri" do
    @client.redirect_uri = nil
    expect(@client).to_not be_valid
  end

  it "is invalid with a non-URI redirect_uri" do
    @client.redirect_uri = 'foo'
    expect(@client).to_not be_valid
  end

  # http://en.wikipedia.org/wiki/HTTP_response_splitting
  it "is invalid if the URI contains HTTP line breaks" do
    @client.redirect_uri = "http://example.com/c\r\nb"
    expect(@client).to_not be_valid
  end

  it "cannot mass-assign client_id" do
    @client.update!(:client_id => 'foo')
    expect(@client.client_id).to_not eq('foo')
  end

  it "cannot mass-assign client_secret" do
    @client.update!(:client_secret => 'foo')
    expect(@client.client_secret).to_not eq('foo')
  end

  it "has client_id and client_secret filled in" do
    expect(@client.client_id).to_not be_nil
    expect(@client.client_secret).to_not be_nil
  end

  it "destroys its authorizations on destroy" do
    @client.destroy
    expect(Songkick::OAuth2::Model::Authorization.count).to be_zero
  end
end

