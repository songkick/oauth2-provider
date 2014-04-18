require 'spec_helper'

describe Songkick::OAuth2::Model::Authorization do
  let(:client)   { Factory :client }
  let(:impostor) { Factory :client }
  let(:owner)    { Factory :owner }
  let(:user)     { Factory :owner }
  let(:tester)   { Factory(:owner) }

  let(:authorization) do
    create_authorization(:owner => tester, :client => client)
  end

  it "is valid" do
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
      create_authorization(
        :owner         => user,
        :client        => impostor,
        :access_token  => 'existing_access_token')

      create_authorization(
        :owner         => user,
        :client        => client,
        :code          => 'existing_code')

      create_authorization(
        :owner         => owner,
        :client        => client,
        :refresh_token => 'existing_refresh_token')
    end

    it "is valid if its access_token is unique" do
      authorization.should be_valid
    end

    it "is valid if both access_tokens are nil" do
      Songkick::OAuth2::Model::Authorization.first.update_attribute(:access_token, nil)
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
      before { Songkick::OAuth2.stub(:random_string).and_return('existing_code', 'new_code') }

      it "returns the first code the client has not used" do
        Songkick::OAuth2::Model::Authorization.create_code(client).should == 'new_code'
      end

      it "returns the first code another client has not used" do
        Songkick::OAuth2::Model::Authorization.create_code(impostor).should == 'existing_code'
      end
    end

    describe ".create_access_token" do
      before { Songkick::OAuth2.stub(:random_string).and_return('existing_access_token', 'new_access_token') }

      it "returns the first unused token it can find" do
        Songkick::OAuth2::Model::Authorization.create_access_token.should == 'new_access_token'
      end
    end

    describe ".create_refresh_token" do
      before { Songkick::OAuth2.stub(:random_string).and_return('existing_refresh_token', 'new_refresh_token') }

      it "returns the first refresh_token the client has not used" do
        Songkick::OAuth2::Model::Authorization.create_refresh_token(client).should == 'new_refresh_token'
      end

      it "returns the first refresh_token another client has not used" do
        Songkick::OAuth2::Model::Authorization.create_refresh_token(impostor).should == 'existing_refresh_token'
      end
    end

    describe "duplicate records" do
      it "raises an error if a duplicate authorization is created" do
        lambda {
          authorization = Songkick::OAuth2::Model::Authorization.__send__(:new)
          authorization.owner = user
          authorization.client = client
          authorization.save
        }.should raise_error
      end

      it "finds an existing record after a race" do
        user.stub(:oauth2_authorization_for) do
          user.unstub(:oauth2_authorization_for)
          raise TypeError, 'Mysql::Error: Duplicate entry'
        end
        authorization = Songkick::OAuth2::Model::Authorization.for(user, client)
        authorization.owner.should == user
        authorization.client.should == client
      end
    end
  end

  describe "#exchange!" do
    it "saves the record" do
      authorization.should_receive(:save!)
      authorization.exchange!
    end

    it "uses its helpers to find unique tokens" do
      Songkick::OAuth2::Model::Authorization.should_receive(:create_access_token).and_return('access_token')
      authorization.exchange!
      authorization.access_token.should == 'access_token'
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
      authorization.grants_access?(tester).should be_true
    end

    it "returns false given the wrong user" do
      authorization.grants_access?(user).should be_false
    end

    describe "when the authorization is expired" do
      before { authorization.expires_at = 2.days.ago }

      it "returns false in all cases" do
        authorization.grants_access?(tester).should be_false
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
        authorization.grants_access?(tester, 'foo', 'bar').should be_true
      end

      it "returns true given the right user and some authorization scopes" do
        authorization.grants_access?(tester, 'bar').should be_true
      end

      it "returns false given the right user and some unauthorization scopes" do
        authorization.grants_access?(tester, 'foo', 'bar', 'qux').should be_false
      end

      it "returns false given an unauthorized scope" do
        authorization.grants_access?(tester, 'qux').should be_false
      end

      it "returns true given the right user" do
        authorization.grants_access?(tester).should be_true
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

