require 'spec_helper'

describe Songkick::OAuth2::Provider::Authorization do
  let(:resource_owner) { TestApp::User['Bob'] }

  let(:authorization) { Songkick::OAuth2::Provider::Authorization.new(resource_owner, params) }

  let(:params) { { 'response_type' => 'code',
                   'client_id'     => @client.client_id,
                   'redirect_uri'  => @client.redirect_uri }
               }

  before do
    @client = Factory(:client)
    Songkick::OAuth2.stub(:random_string).and_return('s1', 's2', 's3')
  end

  describe "with valid parameters" do
    it "is valid" do
      authorization.error.should be_nil
    end
  end

  describe "with the scope parameter" do
    before { params['scope'] = 'foo bar qux' }

    it "exposes the scope as a list of strings" do
      authorization.scopes.should == Set.new(%w[foo bar qux])
    end

    it "exposes the scopes the client has not yet granted" do
      authorization.unauthorized_scopes.should == Set.new(%w[foo bar qux])
    end

    describe "when the owner has already authorized the client" do
      before do
        create_authorization(:owner => resource_owner, :client => @client, :scope => 'foo bar')
      end

      it "exposes the scope as a list of strings" do
        authorization.scopes.should == Set.new(%w[foo bar qux])
      end

      it "exposes the scopes the client has not yet granted" do
        authorization.unauthorized_scopes.should == %w[qux]
      end
    end
  end

  describe "missing response_type" do
    before { params.delete('response_type') }

    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter response_type"
    end
  end

  describe "with a bad response_type" do
    before { params['response_type'] = "no_such_type" }

    it "is invalid" do
      authorization.error.should == "unsupported_response_type"
      authorization.error_description.should == "Response type no_such_type is not supported"
    end

    it "causes a redirect" do
      authorization.should be_redirect
      authorization.redirect_uri.should == "https://client.example.com/cb?error=unsupported_response_type&error_description=Response+type+no_such_type+is+not+supported"
    end
  end

  describe "missing client_id" do
    before { params.delete('client_id') }

    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter client_id"
    end

    it "does not cause a redirect" do
      authorization.should_not be_redirect
    end
  end

  describe "with an unknown client_id" do
    before { params['client_id'] = "unknown" }

    it "is invalid" do
      authorization.error.should == "invalid_client"
      authorization.error_description.should == "Unknown client ID unknown"
    end

    it "does not cause a redirect" do
      authorization.should_not be_redirect
    end
  end

  describe "missing redirect_uri" do
    before { params.delete('redirect_uri') }

    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter redirect_uri"
    end

    it "causes a redirect to the client's registered redirect_uri" do
      authorization.should be_redirect
      authorization.redirect_uri.should == "https://client.example.com/cb?error=invalid_request&error_description=Missing+required+parameter+redirect_uri"
    end
  end

  describe "with a mismatched redirect_uri" do
    before { params['redirect_uri'] = "http://songkick.com" }

    it "is invalid" do
      authorization.error.should == "redirect_uri_mismatch"
      authorization.error_description.should == "Parameter redirect_uri does not match registered URI"
    end

    it "causes a redirect to the client's registered redirect_uri" do
      authorization.should be_redirect
      authorization.redirect_uri.should == "https://client.example.com/cb?error=redirect_uri_mismatch&error_description=Parameter+redirect_uri+does+not+match+registered+URI"
    end

    describe "when the client has not registered a redirect_uri" do
      before { @client.update_attribute(:redirect_uri, nil) }

      it "is valid" do
        authorization.error.should be_nil
      end
    end
  end

  describe "with a redirect_uri with parameters" do
    before do
      authorization.client.redirect_uri = "http://songkick.com?some_parameter"
      params['redirect_uri'] = "http://songkick.com?some_parameter"
    end

    it "adds the extra parameters with & instead of ?" do
      authorization.redirect_uri.should == "http://songkick.com?some_parameter&"
    end
  end

  # http://en.wikipedia.org/wiki/HTTP_response_splitting
  # scope and state values are passed back in the redirect

  describe "with an illegal scope" do
    before { params['scope'] = "http\r\nsplitter" }

    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Illegal value for scope parameter"
    end
  end

  describe "with an illegal state" do
    before { params['state'] = "http\r\nsplitter" }

    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Illegal value for state parameter"
    end
  end

  describe "#grant_access!" do
    describe "when there is an existing authorization with no code" do
      before do
        @model = create_authorization(
          :owner  => resource_owner,
          :client => @client,
          :code   => nil)
      end

      it "generates and returns a code to the client" do
        authorization.grant_access!
        @model.reload
        @model.code.should == "s1"
        authorization.code.should == "s1"
      end
    end

    describe "when there is an existing authorization with scopes" do
      before do
        @model = create_authorization(
          :owner  => resource_owner,
          :client => @client,
          :code   => nil,
          :scope  => 'foo bar')

        params['scope'] = 'qux'
      end

      it "merges the new scopes with the existing ones" do
        authorization.grant_access!
        @model.reload
        @model.scopes.should == Set.new(%w[foo bar qux])
      end
    end

    describe "when there is an existing expired authorization" do
      before do
        @model = create_authorization(
          :owner      => resource_owner,
          :client     => @client,
          :expires_at => 2.months.ago,
          :code       => 'existing_code',
          :scope      => 'foo bar')
      end

      it "renews the authorization" do
        authorization.grant_access!
        @model.reload
        @model.expires_at.should be_nil
      end

      it "returns a code to the client" do
        authorization.grant_access!
        authorization.code.should == "existing_code"
        authorization.access_token.should be_nil
      end

      it "sets the expiry time if a duration is given" do
        authorization.grant_access!(:duration => 1.hour)
        @model.reload
        @model.expires_in.should == 3600
        authorization.expires_in.should == 3600
      end

      it "augments the scope" do
        params['scope'] = 'qux'
        authorization.grant_access!
        @model.reload
        @model.scopes.should == Set.new(%w[foo bar qux])
      end
    end

    describe "for code requests" do
      before do
        params['response_type'] = 'code'
        params['scope'] = 'foo bar'
      end

      it "makes the authorization redirect" do
        authorization.grant_access!
        authorization.client.should_not be_nil
        authorization.should be_redirect
      end

      it "creates a code for the authorization" do
        authorization.grant_access!
        authorization.code.should == "s1"
        authorization.access_token.should be_nil
        authorization.expires_in.should be_nil
      end

      it "creates an Authorization in the database" do
        authorization.grant_access!

        authorization = Songkick::OAuth2::Model::Authorization.first
        authorization.owner.should == resource_owner
        authorization.client.should == @client
        authorization.code.should == "s1"
        authorization.scopes.should == Set.new(%w[foo bar])
      end
    end

    describe "for token requests" do
      before { params['response_type'] = 'token' }

      it "creates a token for the authorization" do
        authorization.grant_access!
        authorization.code.should be_nil
        authorization.access_token.should == "s1"
        authorization.refresh_token.should == "s2"
        authorization.expires_in.should be_nil
      end

      it "creates an Authorization in the database" do
        authorization.grant_access!

        authorization = Songkick::OAuth2::Model::Authorization.first
        authorization.owner.should == resource_owner
        authorization.client.should == @client
        authorization.code.should be_nil
        authorization.access_token_hash.should == Songkick::OAuth2.hashify("s1")
        authorization.refresh_token_hash.should == Songkick::OAuth2.hashify("s2")
      end
    end

    describe "for code_and_token requests" do
      before { params['response_type'] = 'code_and_token' }

      it "creates a code and token for the authorization" do
        authorization.grant_access!
        authorization.code.should == "s1"
        authorization.access_token.should == "s2"
        authorization.refresh_token.should == "s3"
        authorization.expires_in.should be_nil
      end

      it "creates an Authorization in the database" do
        authorization.grant_access!

        authorization = Songkick::OAuth2::Model::Authorization.first
        authorization.owner.should == resource_owner
        authorization.client.should == @client
        authorization.code.should == "s1"
        authorization.access_token_hash.should == Songkick::OAuth2.hashify("s2")
        authorization.refresh_token_hash.should == Songkick::OAuth2.hashify("s3")
      end
    end
  end

  describe "#deny_access!" do
    it "puts the authorization in an error state" do
      authorization.deny_access!
      authorization.error.should == "access_denied"
      authorization.error_description.should == "The user denied you access"
    end

    it "does not create an Authorization" do
      Songkick::OAuth2::Model::Authorization.should_not_receive(:create)
      Songkick::OAuth2::Model::Authorization.should_not_receive(:new)
      authorization.deny_access!
    end
  end

  describe "#params" do
    before do
      params['scope'] = params['state'] = 'valid'
      params['controller'] = 'invalid'
    end

    it "only exposes OAuth-related parameters" do
      authorization.params.should == {
        'response_type' => 'code',
        'client_id'     => @client.client_id,
        'redirect_uri'  => @client.redirect_uri,
        'state'         => 'valid',
        'scope'         => 'valid'
      }
    end

    it "does not expose parameters with no value" do
      params.delete('scope')
      authorization.params.should == {
        'response_type' => 'code',
        'client_id'     => @client.client_id,
        'redirect_uri'  => @client.redirect_uri,
        'state'         => 'valid'
      }
    end
  end
end

