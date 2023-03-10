require 'spec_helper'

describe Songkick::OAuth2::Model::Authorization do
  let(:client)   { FactoryBot.create(:client) }
  let(:impostor) { FactoryBot.create(:client) }
  let(:owner)    { FactoryBot.create(:owner)  }
  let(:user)     { FactoryBot.create(:owner) }
  let(:tester)   { FactoryBot.create(:owner) }

  let(:authorization) do
    create_authorization(:owner => tester, :client => client)
  end

  it "is valid" do
    expect(authorization).to be_valid
  end

  it "is not valid without a client" do
    authorization.client = nil
    expect(authorization).to_not be_valid
  end

  it "is not valid without an owner" do
    authorization.owner = nil
    expect(authorization).to_not be_valid
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
      expect(authorization).to be_valid
    end

    it "is valid if both access_tokens are nil" do
      Songkick::OAuth2::Model::Authorization.first.update_attribute(:access_token, nil)
      authorization.access_token = nil
      expect(authorization).to be_valid
    end

    it "is not valid if its access_token is not unique" do
      authorization.access_token = 'existing_access_token'
      expect(authorization).to_not be_valid
    end

    it "is valid if it has a unique code for its client" do
      authorization.client = impostor
      authorization.code = 'existing_code'
      expect(authorization).to be_valid
    end

    it "is not valid if it does not have a unique client and code" do
      authorization.code = 'existing_code'
      expect(authorization).to_not be_valid
    end

    it "is valid if it has a unique refresh_token for its client" do
      authorization.client = impostor
      authorization.refresh_token = 'existing_refresh_token'
      expect(authorization).to be_valid
    end

    it "is not valid if it does not have a unique client and refresh_token" do
      authorization.refresh_token = 'existing_refresh_token'
      expect(authorization).to_not be_valid
    end

    describe ".create_code" do
      before { allow(Songkick::OAuth2).to receive(:random_string).and_return('existing_code', 'new_code') }

      it "returns the first code the client has not used" do
        expect(Songkick::OAuth2::Model::Authorization.create_code(client)).to eq('new_code')
      end

      it "returns the first code another client has not used" do
        expect(Songkick::OAuth2::Model::Authorization.create_code(impostor)).to eq('existing_code')
      end
    end

    describe ".create_access_token" do
      before { allow(Songkick::OAuth2).to receive(:random_string).and_return('existing_access_token', 'new_access_token') }

      it "returns the first unused token it can find" do
        expect(Songkick::OAuth2::Model::Authorization.create_access_token).to eq('new_access_token')
      end
    end

    describe ".create_refresh_token" do
      before { allow(Songkick::OAuth2).to receive(:random_string).and_return('existing_refresh_token', 'new_refresh_token') }

      it "returns the first refresh_token the client has not used" do
        expect(Songkick::OAuth2::Model::Authorization.create_refresh_token(client)).to eq('new_refresh_token')
      end

      it "returns the first refresh_token another client has not used" do
        expect(Songkick::OAuth2::Model::Authorization.create_refresh_token(impostor)).to eq('existing_refresh_token')
      end
    end

    describe "duplicate records" do
      it "raises an error if a duplicate authorization is created" do
        expect {
          authorization = Songkick::OAuth2::Model::Authorization.__send__(:new)
          authorization.owner = user
          authorization.client = client
          authorization.save
        }.to raise_error
      end

      it "finds an existing record after a race" do
        allow(user).to receive(:oauth2_authorization_for) do
          allow(user).to receive(:oauth2_authorization_for).and_call_original
          raise TypeError, 'Mysql::Error: Duplicate entry'
        end
        authorization = Songkick::OAuth2::Model::Authorization.for(user, client)
        expect(authorization.owner).to eq(user)
        expect(authorization.client).to eq(client)
      end
    end
  end

  describe "#exchange!" do
    it "saves the record" do
      expect(authorization).to receive(:save!)
      authorization.exchange!
    end

    it "uses its helpers to find unique tokens" do
      expect(Songkick::OAuth2::Model::Authorization).to receive(:create_access_token).and_return('access_token')
      authorization.exchange!
      expect(authorization.access_token).to eq('access_token')
    end

    it "updates the tokens correctly" do
      authorization.exchange!
      expect(authorization).to be_valid
      expect(authorization.code).to be_nil
      expect(authorization.refresh_token).to be_nil
    end
  end

  describe "#expired?" do
    it "returns false when not expiry is set" do
      expect(authorization).to_not be_expired
    end

    it "returns false when expiry is in the future" do
      authorization.expires_at = 2.days.from_now
      expect(authorization).to_not be_expired
    end

    it "returns true when expiry is in the past" do
      authorization.expires_at = 2.days.ago
      expect(authorization).to be_expired
    end
  end

  describe "#grants_access?" do
    it "returns true given the right user" do
      expect(authorization.grants_access?(tester)).to be(true)
    end

    it "returns false given the wrong user" do
      expect(authorization.grants_access?(user)).to be(false)
    end

    describe "when the authorization is expired" do
      before { authorization.expires_at = 2.days.ago }

      it "returns false in all cases" do
        expect(authorization.grants_access?(tester)).to be(false)
        expect(authorization.grants_access?(user)).to be(false)
      end
    end
  end

  describe "with a scope" do
    before { authorization.scope = 'foo bar' }

    describe "#in_scope?" do
      it "returns true for authorized scopes" do
        expect(authorization).to be_in_scope('foo')
        expect(authorization).to be_in_scope('bar')
      end

      it "returns false for unauthorized scopes" do
        expect(authorization).to_not be_in_scope('qux')
        expect(authorization).to_not be_in_scope('fo')
      end
    end

    describe "#grants_access?" do
      it "returns true given the right user and all authorization scopes" do
        expect(authorization.grants_access?(tester, 'foo', 'bar')).to be(true)
      end

      it "returns true given the right user and some authorization scopes" do
        expect(authorization.grants_access?(tester, 'bar')).to be(true)
      end

      it "returns false given the right user and some unauthorization scopes" do
        expect(authorization.grants_access?(tester, 'foo', 'bar', 'qux')).to be(false)
      end

      it "returns false given an unauthorized scope" do
        expect(authorization.grants_access?(tester, 'qux')).to be(false)
      end

      it "returns true given the right user" do
        expect(authorization.grants_access?(tester)).to be(true)
      end

      it "returns false given the wrong user" do
        expect(authorization.grants_access?(user)).to be(false)
      end

      it "returns false given the wrong user and an authorized scope" do
        expect(authorization.grants_access?(user, 'foo')).to be(false)
      end
    end
  end
end

