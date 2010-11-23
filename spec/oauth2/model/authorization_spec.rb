require 'spec_helper'

describe OAuth2::Model::Authorization do
  let(:client)   { Factory :client }
  let(:impostor) { Factory :client }
  let(:owner)    { Factory :owner }
  let(:user)     { Factory :owner }
  
  let(:authorization) do
    OAuth2::Model::Authorization.new(:owner => owner, :client => client)
  end
  
  it "is vaid" do
    authorization.should be_valid
  end
  
  it "is not valid without a client" do
    authorization.client = nil
    authorization.should_not be_valid
  end
  
  it "is not valid without an owner" do
    authorization.owner = nil
    authorization.should_not be_valid
  end
  
  describe "when there are existing authorizations" do
    before do
      OAuth2::Model::Authorization.create(
        :owner        => user,
        :client       => impostor,
        :access_token => 'foo')
    end
    
    it "is valid if its access_token is unique" do
      authorization.should be_valid
    end
    
    it "is valid if both access_tokens are nil" do
      OAuth2::Model::Authorization.first.update_attribute(:access_token, nil)
      authorization.access_token = nil
      authorization.should be_valid
    end
    
    it "is not valid if its access_token is not unique" do
      authorization.access_token = 'foo'
      authorization.should_not be_valid
    end
    
    describe "#update_tokens" do
      before do
        authorization # load before stubbing random_string
        OAuth2.stub(:random_string).and_return('foo', 'bar')
      end
      
      it "saves the record" do
        authorization.should_receive(:save)
        authorization.update_tokens
      end
      
      it "tries tokens until it gets a unique one" do
        authorization.update_tokens
        authorization.should be_valid
        authorization.access_token.should == 'bar'
      end
    end
  end
  
  describe "#expired?" do
    it "returns false when not expiry is set" do
      authorization.should_not be_expired
    end
    
    it "returns false when expiry is in the future" do
      authorization.expires_at = 2.days.from_now
      authorization.should_not be_expired
    end
    
    it "returns true when expiry is in the past" do
      authorization.expires_at = 2.days.ago
      authorization.should be_expired
    end
  end
  
  describe "#grants_access?" do
    it "returns true given the right user" do
      authorization.grants_access?(owner).should be_true
    end
    
    it "returns false given the wrong user" do
      authorization.grants_access?(user).should be_false
    end
    
    describe "when the authorization is expired" do
      before { authorization.expires_at = 2.days.ago }
      
      it "returns false in all cases" do
        authorization.grants_access?(owner).should be_false
        authorization.grants_access?(user).should be_false
      end
    end
  end
  
  describe "with a scope" do
    before { authorization.scope = 'foo bar' }
    
    describe "#in_scope?" do
      it "returns true for authorized scopes" do
        authorization.should be_in_scope('foo')
        authorization.should be_in_scope('bar')
      end
      
      it "returns false for unauthorized scopes" do
        authorization.should_not be_in_scope('qux')
        authorization.should_not be_in_scope('fo')
      end
    end
    
    describe "#grants_access?" do
      it "returns true given the right user and all authorization scopes" do
        authorization.grants_access?(owner, 'foo', 'bar').should be_true
      end
      
      it "returns true given the right user and some authorization scopes" do
        authorization.grants_access?(owner, 'bar').should be_true
      end
      
      it "returns false given the right user and some unauthorization scopes" do
        authorization.grants_access?(owner, 'foo', 'bar', 'qux').should be_false
      end
      
      it "returns false given an unauthorized scope" do
        authorization.grants_access?(owner, 'qux').should be_false
      end
      
      it "returns false given the right user" do
        authorization.grants_access?(owner).should be_true
      end
      
      it "returns false given the wrong user" do
        authorization.grants_access?(user).should be_false
      end
      
      it "returns false given the wrong user and an authorized scope" do
        authorization.grants_access?(user, 'foo').should be_false
      end
    end
  end
end

