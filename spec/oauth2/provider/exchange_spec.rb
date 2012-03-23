require 'spec_helper'

describe OAuth2::Provider::Exchange do
  before do
    @client = Factory(:client)
    @owner  = TestApp::User['Bob']
    @authorization = Factory(:authorization, :client => @client, :owner => @owner, :scope => 'foo bar')
    OAuth2.stub(:random_string).and_return('random_string')
  end
  
  let(:exchange) { OAuth2::Provider::Exchange.new(@owner, params) }
  
  shared_examples_for "validates required parameters" do
    describe "missing grant_type" do
      before { params.delete('client_id') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter client_id"
      end
    end
    
    describe "with an unknown grant type" do
      before { params['grant_type'] = 'unknown' }
      
      it "is invalid" do
        exchange.error.should == "unsupported_grant_type"
        exchange.error_description.should == "The grant type unknown is not recognized"
      end
    end
    
    describe "missing client_id" do
      before { params.delete('client_id') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter client_id"
      end
    end
    
    describe "with an unknown client_id" do
      before { params['client_id'] = "unknown" }
      
      it "is invalid" do
        exchange.error.should == "invalid_client"
        exchange.error_description.should == "Unknown client ID unknown"
      end
    end
    
    describe "missing client_secret" do
      before { params.delete('client_secret') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter client_secret"
      end
    end
    
    describe "with a mismatched client_secret" do
      before { params['client_secret'] = "nosoupforyou" }
      
      it "is invalid" do
        exchange.error.should == "invalid_client"
        exchange.error_description.should == "Parameter client_secret does not match"
      end
    end
    
    describe "with lesser scope than the authorization code represents" do
      before { params['scope'] = 'bar' }
      
      it "is valid" do
        exchange.error.should be_nil
      end
    end
    
    describe "with scopes not covered by the authorization code" do
      before { params['scope'] = 'qux' }
      
      it "is invalid" do
        exchange.error.should == 'invalid_scope'
        exchange.error_description.should == 'The request scope was never granted by the user'
      end
    end
  end
  
  shared_examples_for "valid token request" do
    before do
      OAuth2.stub(:random_string).and_return('random_access_token')
    end
    
    it "is valid" do
      exchange.error.should be_nil
    end
    
    it "updates the Authorization with tokens" do
      exchange.update_authorization
      authorization.reload
      authorization.code.should be_nil
      authorization.access_token_hash.should == OAuth2.hashify('random_access_token')
      authorization.refresh_token.should be_nil
    end
  end
  
  describe "using authorization_code grant type" do
    let(:params) { { 'client_id'     => @client.client_id,
                     'client_secret' => @client.client_secret,
                     'grant_type'    => 'authorization_code',
                     'code'          => @authorization.code,
                     'redirect_uri'  => @client.redirect_uri }
                 }
    
    let(:authorization) { @authorization }
    
    it_should_behave_like "validates required parameters"
    it_should_behave_like "valid token request"
    
    describe "missing redirect_uri" do
      before { params.delete('redirect_uri') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter redirect_uri"
      end
    end
    
    describe "with a mismatched redirect_uri" do
      before { params['redirect_uri'] = "http://songkick.com" }
      
      it "is invalid" do
        exchange.error.should == "redirect_uri_mismatch"
        exchange.error_description.should == "Parameter redirect_uri does not match registered URI"
      end
      
      describe "when the client has not registered a redirect_uri" do
        before { @client.update_attribute(:redirect_uri, nil) }
        
        it "is valid" do
          exchange.error.should be_nil
        end
      end
    end
    
    describe "missing code" do
      before { params.delete('code') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter code"
      end
    end
    
    describe "with an unknown code" do
      before { params['code'] = "unknown" }
      
      it "is invalid" do
        exchange.error.should == "invalid_grant"
        exchange.error_description.should == "The access grant you supplied is invalid"
      end
    end
    
    describe "with an expired code" do
      before { @authorization.update_attribute(:expires_at, 1.day.ago) }
      
      it "is invalid" do
        exchange.error.should == "invalid_grant"
        exchange.error_description.should == "The access grant you supplied is invalid"
      end
    end
  end
  
  describe "using password grant type" do
    let(:params) { { 'client_id'      => @client.client_id,
                     'client_secret'  => @client.client_secret,
                     'grant_type'     => 'password',
                     'username'       => 'Bob',
                     'password'       => 'soldier' }
                 }
    
    let(:authorization) { @authorization }
    
    before do
      OAuth2::Provider.handle_passwords do |client, username, password|
        user = TestApp::User[username]
        if password == 'soldier'
          user.grant_access!(client, :scopes => ['foo', 'bar'])
        else
          nil
        end
      end
    end
    
    it_should_behave_like "validates required parameters"
    it_should_behave_like "valid token request"
    
    describe "missing username" do
      before { params.delete('username') }
      
      it "is invalid" do
        exchange.error.should == 'invalid_request'
        exchange.error_description.should == 'Missing required parameter username'
      end
    end
    
    describe "missing password" do
      before { params.delete('password') }
      
      it "is invalid" do
        exchange.error.should == 'invalid_request'
        exchange.error_description.should == 'Missing required parameter password'
      end
    end
    
    describe "with a bad password" do
      before { params['password'] = 'bad' }
      
      it "is invalid" do
        exchange.error.should == 'invalid_grant'
        exchange.error_description.should == 'The access grant you supplied is invalid'
      end
    end
  end
  
  describe "using assertion grant type" do
    let(:params) { { 'client_id'      => @client.client_id,
                     'client_secret'  => @client.client_secret,
                     'grant_type'     => 'assertion',
                     'assertion_type' => 'https://graph.facebook.com/me',
                     'assertion'      => 'Bob' }
                 }
    
    let(:authorization) { @authorization }
    
    before do
      OAuth2::Provider.filter_assertions { |client| @client == client }
      
      OAuth2::Provider.handle_assertions('https://graph.facebook.com/me') do |client, assertion|
        user = TestApp::User[assertion]
        user.grant_access!(client, :scopes => ['foo', 'bar'])
      end
    end
    
    after do
      OAuth2::Provider.clear_assertion_handlers!
    end
    
    describe "missing grant_type" do
      before { params.delete('client_id') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter client_id"
      end
    end
    
    describe "with an unknown grant type" do
      before { params['grant_type'] = 'unknown' }
      
      it "is invalid" do
        exchange.error.should == "unsupported_grant_type"
        exchange.error_description.should == "The grant type unknown is not recognized"
      end
    end
    
    describe "missing client_id" do
      before { params.delete('client_id') }
      
      it "is invalid" do
        exchange.error.should == "invalid_request"
        exchange.error_description.should == "Missing required parameter client_id"
      end
    end
    
    describe "with an unknown client_id" do
      before { params['client_id'] = "unknown" }
      
      it "is invalid" do
        exchange.error.should == "invalid_client"
        exchange.error_description.should == "Unknown client ID unknown"
      end
    end
    
    describe "with a mismatched client_secret" do
      before { params['client_secret'] = "nosoupforyou" }
      
      it "is invalid" do
        exchange.error.should == "invalid_client"
        exchange.error_description.should == "Parameter client_secret does not match"
      end
    end
    
    describe "with lesser scope than the authorization code represents" do
      before { params['scope'] = 'bar' }
      
      it "is valid" do
        exchange.error.should be_nil
      end
    end
    
    describe "with scopes not covered by the authorization code" do
      before { params['scope'] = 'qux' }
      
      it "is invalid" do
        exchange.error.should == 'invalid_scope'
        exchange.error_description.should == 'The request scope was never granted by the user'
      end
    end

    it_should_behave_like "valid token request"
    
    describe "missing assertion_type" do
      before { params.delete('assertion_type') }
      
      it "is invalid" do
        exchange.error.should == 'invalid_request'
        exchange.error_description.should == 'Missing required parameter assertion_type'
      end
    end
    
    describe "with a non-URI assertion_type" do
      before { params['assertion_type'] = 'invalid' }
      
      it "is invalid" do
        exchange.error.should == 'invalid_request'
        exchange.error_description.should == 'Parameter assertion_type must be an absolute URI'
      end
    end
    
    describe "missing assertion" do
      before { params.delete('assertion') }
      
      it "is invalid" do
        exchange.error.should == 'invalid_request'
        exchange.error_description.should == 'Missing required parameter assertion'
      end
    end
    
    describe "with an unrecognized assertion_type" do
      before { params['assertion_type'] = 'https://oauth.what.com/ohai' }
      
      it "is invalid" do
        exchange.error.should == 'unauthorized_client'
        exchange.error_description.should == 'Client cannot use the given assertion type'
      end
    end
    
    describe "with a client unauthorized to use the assertion scheme" do
      before do
        client = Factory(:client)
        params['client_id'] = client.client_id
        params['client_secret'] = client.client_secret
      end
      
      it "is invalid" do
        exchange.error.should == 'unauthorized_client'
        exchange.error_description.should == 'Client cannot use the given assertion type'
      end
    end
  end
  
  describe "using refresh_token grant type" do
    before do
      @refresher = Factory(:authorization, :client => @client,
                                           :owner  => @owner,
                                           :scope  => 'foo bar',
                                           :code   => nil,
                                           :refresh_token => 'roflscale')
    end
    
    let(:params) { { 'client_id'     => @client.client_id,
                     'client_secret' => @client.client_secret,
                     'grant_type'    => 'refresh_token',
                     'refresh_token' => 'roflscale' }
                 }
    
    let(:authorization) { @refresher }
    
    it_should_behave_like "validates required parameters"
    it_should_behave_like "valid token request"
    
    describe "with unknown refresh_token" do
      before { params['refresh_token'] = 'woops' }
      
      it "is invalid" do
        exchange.error.should == "invalid_grant"
        exchange.error_description.should == "The access grant you supplied is invalid"
      end
    end
  
  end
end

