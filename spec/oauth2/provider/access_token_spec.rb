require 'spec_helper'

describe OAuth2::Provider::AccessToken do
  before do
    @alice = TestApp::User['Alice']
    @bob   = TestApp::User['Bob']
    
    Factory(:authorization,
      :owner        => @alice,
      :scope        => 'profile',
      :access_token => 'sesame')
    
    @authorization = Factory(:authorization,
      :owner        => @bob,
      :scope        => 'profile',
      :access_token => 'magic-key')
    
    OAuth2.realm = 'Demo App'
  end
  
  let :token do
    OAuth2::Provider::AccessToken.new(@bob, ['profile'], 'magic-key')
  end
  
  shared_examples_for "valid token" do
    it "is valid" do
      token.should be_valid
    end
    it "does not add headers" do
      token.response_headers.should == {}
    end
    it "has an OK status code" do
      token.response_status.should == 200
    end
    it "returns the owner who granted the authorization" do
      token.owner.should == @bob
    end
  end
  
  shared_examples_for "invalid token" do
    it "is not valid" do
      token.should_not be_valid
    end
    it "does not return the owner" do
      token.owner.should be_nil
    end
  end
  
  describe "with the right user, scope and token" do
    it_should_behave_like "valid token"
  end
  
  describe "with no user" do
    let :token do
      OAuth2::Provider::AccessToken.new(nil, ['profile'], 'magic-key')
    end
    it_should_behave_like "valid token"
  end
  
  describe "with less scope than was granted" do
    let :token do
      OAuth2::Provider::AccessToken.new(@bob, [], 'magic-key')
    end
    it_should_behave_like "valid token"
  end
  
  describe "when the authorization has expired" do
    before { @authorization.update_attribute(:expires_at, 1.hour.ago) }
    it_should_behave_like "invalid token"
    
    it "returns an error response" do
      token.response_headers['WWW-Authenticate'].should == "OAuth realm='Demo App', error='expired_token'"
      token.response_status.should == 401
    end
  end
  
  describe "with a non-existant token" do
    let :token do
      OAuth2::Provider::AccessToken.new(@bob, ['profile'], 'is-the-password-books')
    end
    it_should_behave_like "invalid token"
    
    it "returns an error response" do
      token.response_headers['WWW-Authenticate'].should == "OAuth realm='Demo App', error='invalid_token'"
      token.response_status.should == 401
    end
  end
  
  describe "with a token for the wrong user" do
    let :token do
      OAuth2::Provider::AccessToken.new(@bob, ['profile'], 'sesame')
    end
    it_should_behave_like "invalid token"
    
    it "returns an error response" do
      token.response_headers['WWW-Authenticate'].should == "OAuth realm='Demo App', error='insufficient_scope'"
      token.response_status.should == 403
    end
  end
  
  describe "with a token for an ungranted scope" do
    let :token do
      OAuth2::Provider::AccessToken.new(@bob, ['offline_access'], 'magic-key')
    end
    it_should_behave_like "invalid token"
    
    it "returns an error response" do
      token.response_headers['WWW-Authenticate'].should == "OAuth realm='Demo App', error='insufficient_scope'"
      token.response_status.should == 403
    end
  end
  
  describe "with no token string" do
    let :token do
      OAuth2::Provider::AccessToken.new(@bob, ['profile'], nil)
    end
    it_should_behave_like "invalid token"
    
    it "returns an error response" do
      token.response_headers['WWW-Authenticate'].should == "OAuth realm='Demo App'"
      token.response_status.should == 401
    end
  end
end

