require 'spec_helper'

describe OAuth2::Provider do
  before { TestApp::Provider.start(8000) }
  after  { TestApp::Provider.stop }
  
  let(:params) { { 'response_type' => 'code',
                   'client_id'     => @client.client_id,
                   'redirect_uri'  => @client.redirect_uri }
               }
  
  before do
    @client = Factory(:client, :name => 'Test client')
  end
  
  def get(query_params)
    qs  = params.map { |k,v| "#{ URI.escape k.to_s }=#{ URI.escape v.to_s }" }.join('&')
    uri = URI.parse('http://localhost:8000/authorize?' + qs)
    Net::HTTP.get_response(uri)
  end
  
  def post_basic_auth(auth_params, query_params)
    url = "http://#{ auth_params['client_id'] }:#{ auth_params['client_secret'] }@localhost:8000/authorize"
    Net::HTTP.post_form(URI.parse(url), query_params)
  end
  
  def post(query_params)
    Net::HTTP.post_form(URI.parse('http://localhost:8000/authorize'), query_params)
  end
  
  def allow_or_deny(query_params)
    Net::HTTP.post_form(URI.parse('http://localhost:8000/allow'), query_params)
  end
  
  def mock_request(request_class, stubs = {})
    mock_request = mock(request_class)
    method_stubs = {
      :redirect?        => false,
      :response_body    => nil,
      :response_headers => {},
      :response_status  => 200
    }.merge(stubs)
    
    method_stubs.each do |method, value|
      mock_request.should_receive(method).and_return(value)
    end
    
    mock_request
  end
  
  describe "authorization request" do
    shared_examples_for "creates authorization" do
      it "creates an authorization" do
        auth = mock_request(OAuth2::Provider::Authorization, :client => @client, :params => {})
        OAuth2::Provider::Authorization.should_receive(:new).with(params).and_return(auth)
        get(params)
      end
      
      it "displays an authorization page" do
        response = get(params)
        response.code.to_i.should == 200
        response.body.should =~ /Do you want to allow Test client/
      end
    end
    
    describe "with valid parameters" do
      it_should_behave_like "creates authorization"
    end
    
    describe "for token requests" do
      before { params['response_type'] = 'token' }
      it_should_behave_like "creates authorization"
    end
    
    describe "for code_and_token requests" do
      before { params['response_type'] = 'code_and_token' }
      it_should_behave_like "creates authorization"
    end
    
    describe "with an invalid request" do
      before { params.delete('response_type') }
      
      it "redirects to the client's redirect_uri on error" do
        response = get(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=invalid_request&error_description=Missing%20required%20parameter%20response_type'
      end
      
      describe "with a state parameter" do
        before { params['state'] = 'foo' }
      
        it "redirects to the client, including the state param" do
          response = get(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?error=invalid_request&error_description=Missing%20required%20parameter%20response_type&state=foo'
        end
      end
    end
  end
  
  describe "authorization confirmation from the user" do
    let(:mock_auth) do
      mock = mock(OAuth2::Provider::Authorization)
      mock.stub(:redirect_uri).and_return('http://example.com/')
      OAuth2::Provider::Authorization.stub(:new).and_return(mock)
      mock
    end
    
    describe "without the user's permission" do
      before { params['allow'] = '' }
      
      it "does not grant access" do
        mock_auth.should_receive(:deny_access)
        allow_or_deny(params)
      end
      
      it "redirects to the client with an error" do
        response = allow_or_deny(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=access_denied&error_description=The%20user%20denied%20you%20access'
      end
    end
    
    describe "with valid parameters and user permission" do
      before { OAuth2.stub(:random_string).and_return('foo') }
      before { params['allow'] = '1' }
      
      describe "for code requests" do
        it "grants access" do
          mock_auth.should_receive(:grant_access)
          allow_or_deny(params)
        end
        
        it "redirects to the client with an authorization code" do
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&expires_in=3600'
        end
        
        it "passes the state parameter through" do
          params['state'] = 'illinois'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&expires_in=3600&state=illinois'
        end
        
        it "passes the scope parameter through" do
          params['scope'] = 'foo bar'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&expires_in=3600&scope=foo%20bar'
        end
      end
      
      describe "for token requests" do
        before { params['response_type'] = 'token' }
        
        it "grants access" do
          mock_auth.should_receive(:grant_access)
          allow_or_deny(params)
        end
        
        it "redirects to the client with an access token" do
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=foo&expires_in=3600'
        end
        
        it "passes the state parameter through" do
          params['state'] = 'illinois'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=foo&expires_in=3600&state=illinois'
        end
        
        it "passes the scope parameter through" do
          params['scope'] = 'foo bar'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=foo&expires_in=3600&scope=foo%20bar'
        end
      end
      
      describe "for code_and_token requests" do
        before { params['response_type'] = 'code_and_token' }
        
        it "grants access" do
          mock_auth.should_receive(:grant_access)
          allow_or_deny(params)
        end
        
        it "redirects to the client with an access token" do
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo#access_token=foo&expires_in=3600'
        end
        
        it "passes the state parameter through" do
          params['state'] = 'illinois'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&state=illinois#access_token=foo&expires_in=3600'
        end
        
        it "passes the scope parameter through" do
          params['scope'] = 'foo bar'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo#access_token=foo&expires_in=3600&scope=foo%20bar'
        end
      end
    end
  end
  
  describe "access token request" do
    before do
      @client = Factory(:client)
      @owner  = Factory(:owner)
      @authorization = Factory(:authorization, :client => @client, :owner => @owner)
    end
    
    let(:auth_params)  { { 'client_id'     => @client.client_id,
                           'client_secret' => @client.client_secret }
                       }
    
    def validate_response(response, status, body)
      response.code.to_i.should == status
      JSON.parse(response.body).should == body
      response['Content-Type'].should == 'application/json'
      response['Cache-Control'].should == 'no-store'
    end
    
    describe "using authorization_code request" do
      let(:query_params) { { 'client_id'    => @client.client_id,
                             'grant_type'   => 'authorization_code',
                             'code'         =>  @authorization.code,
                             'redirect_uri' => @client.redirect_uri }
                         }
      
      let(:params) { auth_params.merge(query_params) }
      
      describe "with valid parameters" do
        it "does not respond to GET" do
          OAuth2::Provider::Authorization.should_not_receive(:new)
          OAuth2::Provider::Token.should_not_receive(:new)
          response = get(params)
          validate_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Bad request'
          )
        end
        
        it "creates a Token when using Basic Auth" do
          token = mock_request(OAuth2::Provider::Token, :response_body => 'Hello')
          OAuth2::Provider::Token.should_receive(:new).with(params).and_return(token)
          post_basic_auth(auth_params, query_params)
        end
        
        it "creates a Token when passing params in the POST body" do
          token = mock_request(OAuth2::Provider::Token, :response_body => 'Hello')
          OAuth2::Provider::Token.should_receive(:new).with(params).and_return(token)
          post(params)
        end
        
        it "returns a successful response" do
          OAuth2.stub(:random_string).and_return('random_access_token', 'random_refresh_token')
          
          response = post_basic_auth(auth_params, query_params)
          validate_response(response, 200,
            'access_token'  => 'random_access_token',
            'expires_in'    => 3600,
            'refresh_token' => 'random_refresh_token'
          )
        end
      end
      
      describe "with invalid parameters" do
        before { query_params.delete('code') }
        
        it "returns an error response" do
          response = post_basic_auth(auth_params, query_params)
          validate_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Missing required parameter code'
          )
        end
      end
      
      describe "with mismatched client_id in POST params and Basic Auth params" do
        before { query_params['client_id'] = 'foo' }
        
        it "returns an error response" do
          response = post_basic_auth(auth_params, query_params)
          validate_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Bad request: client_id from Basic Auth and request body do not match'
          )
        end
      end
    end
  end
end

