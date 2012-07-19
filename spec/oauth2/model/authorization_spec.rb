require 'spec_helper'

describe OAuth2::Model::Authorization do
  let(:client)   { Factory :client }
  let(:impostor) { Factory :client }
  let(:owner)    { Factory :owner }
  let(:user)     { Factory :owner }

  let(:authorization) do
    OAuth2::Model::Authorization.new do |auth|
      auth.owner = owner
      auth.client = client
  end
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
      OAuth2::Model::Authorization.create do |auth|
        auth.owner         = user
        auth.client        = impostor
        auth.access_token  = 'existing_access_token'
      end

      OAuth2::Model::Authorization.create do |auth|
        auth.owner         = owner
        auth.client        = client
        auth.code          = 'existing_code'
      end

      OAuth2::Model::Authorization.create do |auth|
        auth.owner         = owner
        auth.client        = client
        auth.refresh_token = 'existing_refresh_token'
      end
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
      authorization.access_token = 'existing_access_token'
      authorization.should_not be_valid
    end

    it "is valid if it has a unique code for its client" do
      authorization.client = impostor
      authorization.code = 'existing_code'
      authorization.should be_valid
    end

    it "is not valid if it does not have a unique client and code" do
      authorization.code = 'existing_code'
      authorization.should_not be_valid
    end

    it "is valid if it has a unique refresh_token for its client" do
      authorization.client = impostor
      authorization.refresh_token = 'existing_refresh_token'
      authorization.should be_valid
    end

    it "is not valid if it does not have a unique client and refresh_token" do
      authorization.refresh_token = 'existing_refresh_token'
      authorization.should_not be_valid
    end

    describe ".create_code" do
      before { OAuth2.stub(:random_string).and_return('existing_code', 'new_code') }

      it "returns the first code the client has not used" do
        OAuth2::Model::Authorization.create_code(client).should be == 'new_code'
      end

      it "returns the first code another client has not used" do
        OAuth2::Model::Authorization.create_code(impostor).should be == 'existing_code'
      end
    end

    describe ".create_access_token" do
      before { OAuth2.stub(:random_string).and_return('existing_access_token', 'new_access_token') }

      it "returns the first unused token it can find" do
        OAuth2::Model::Authorization.create_access_token.should be == 'new_access_token'
      end
    end

    describe ".create_refresh_token" do
      before { OAuth2.stub(:random_string).and_return('existing_refresh_token', 'new_refresh_token') }

      it "returns the first refresh_token the client has not used" do
        OAuth2::Model::Authorization.create_refresh_token(client).should be == 'new_refresh_token'
      end

      it "returns the first refresh_token another client has not used" do
        OAuth2::Model::Authorization.create_refresh_token(impostor).should be == 'existing_refresh_token'
      end
    end
  end

  describe "#exchange!" do
    it "saves the record" do
      authorization.should_receive(:save!)
      authorization.exchange!
    end

    it "uses its helpers to find unique tokens" do
      OAuth2::Model::Authorization.should_receive(:create_access_token).and_return('access_token')
      authorization.exchange!
      authorization.access_token.should be == 'access_token'
    end

    it "updates the tokens correctly" do
      authorization.exchange!
      authorization.should be_valid
      authorization.code.should be_nil
      authorization.refresh_token.should be_nil
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

      it "returns true given the right user" do
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

