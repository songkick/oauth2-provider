require 'spec_helper'

describe OAuth2::Model::AuthorizationOwner do
  before do
    @owner  = Factory(:owner)
    @client = Factory(:client)
  end
  
  describe "#grant_access!" do
    it "creates an authorization between the owner and the client" do
      OAuth2::Model::Authorization.should_receive(:create).with(:owner => @owner, :client => @client)
      @owner.grant_access!(@client)
    end
    
    it "returns the authorization" do
      @owner.grant_access!(@client).should be_kind_of(OAuth2::Model::Authorization)
    end
  end
  
  describe "when there is an existing authorization" do
    before do
      @authorization = Factory(:authorization, :owner => @owner, :client => @client)
    end
    
    it "does not create a new one" do
      OAuth2::Model::Authorization.should_not_receive(:create)
      @owner.grant_access!(@client)
    end
    
    it "updates the authorization with scopes" do
      @owner.grant_access!(@client, :scopes => ['foo', 'bar'])
      @authorization.reload
      @authorization.scopes.should == ['foo', 'bar']
    end
  end
  
  it "destroys its authorizations on destroy" do
    Factory(:authorization, :owner => @owner, :client => @client)
    @owner.destroy
    OAuth2::Model::Authorization.count.should be_zero
  end
end

