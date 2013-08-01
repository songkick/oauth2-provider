require 'spec_helper'

describe Songkick::OAuth2::Provider do
  include RequestHelpers

  before(:all) { TestApp::Provider.start(RequestHelpers::SERVER_PORT) }
  after(:all)  { TestApp::Provider.stop }

  let(:params) { { 'response_type' => 'code',
                   'client_id'     => @client.client_id,
                   'redirect_uri'  => @client.redirect_uri }
               }

  before do
    @client = Factory(:client, :name => 'Test client')
    @owner  = TestApp::User['Bob']
  end

  describe "access grant request" do
    shared_examples_for "asks for user permission" do
      it "creates an authorization" do
        auth = mock_request(Songkick::OAuth2::Provider::Authorization, :client => @client, :params => {}, :scopes => [], :valid? => true)
        Songkick::OAuth2::Provider::Authorization.should_receive(:new).with(@owner, params, nil).and_return(auth)
        get(params)
      end

      it "displays an authorization page" do
        response = get(params)
        response.code.to_i.should == 200
        response.body.should =~ /Do you want to allow Test client/
        response['Content-Type'].should =~ /text\/html/
      end
    end

    describe "with valid parameters" do
      it_should_behave_like "asks for user permission"
    end

    describe "for token requests" do
      before { params['response_type'] = 'token' }
      it_should_behave_like "asks for user permission"
    end

    describe "for code_and_token requests" do
      before { params['response_type'] = 'code_and_token' }
      it_should_behave_like "asks for user permission"
    end

    describe "enforcing SSL" do
      before { Songkick::OAuth2::Provider.enforce_ssl = true }

      it "does not allow non-SSL requests" do
        response = get(params)
        validate_response(response, 400, 'WAT')
      end
    end

    describe "when there is already a pending authorization from the user" do
      before do
        @authorization = create_authorization(
          :owner  => @owner,
          :client => @client,
          :code   => 'pending_code',
          :scope  => 'offline_access')
      end

      it "immediately redirects with the code" do
        response = get(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?code=pending_code'
      end

      describe "when the client is requesting scopes it already has access to" do
        before { params['scope'] = 'offline_access' }

        it "immediately redirects with the code" do
          response = get(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=pending_code&scope=offline_access'
        end
      end

      describe "when the client is requesting scopes it doesn't have yet" do
        before { params['scope'] = 'wall_publish' }
        it_should_behave_like "asks for user permission"
      end

      describe "and the authorization does not have a code" do
        before { @authorization.update_attribute(:code, nil) }

        it "generates a new code and redirects" do
          Songkick::OAuth2::Model::Authorization.should_not_receive(:create)
          Songkick::OAuth2::Model::Authorization.should_not_receive(:new)
          Songkick::OAuth2.should_receive(:random_string).and_return('new_code')
          response = get(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=new_code'
        end
      end

      describe "and the authorization is expired" do
        before { @authorization.update_attribute(:expires_at, 2.hours.ago) }
        it_should_behave_like "asks for user permission"
      end
    end

    describe "when there is already a completed authorization from the user" do
      before do
        @authorization = create_authorization(
          :owner  => @owner,
          :client => @client,
          :code   => nil,
          :access_token => Songkick::OAuth2.hashify('complete_token'))
      end

      it "immediately redirects with a new code" do
        Songkick::OAuth2.should_receive(:random_string).and_return('new_code')
        response = get(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?code=new_code'
      end

      describe "for token requests" do
        before { params['response_type'] = 'token' }

        it "immediately redirects with a new token" do
          Songkick::OAuth2.should_receive(:random_string).and_return('new_access_token')
          response = get(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=new_access_token'
        end

        describe "with an invalid client_id" do
          before { params['client_id'] = 'unknown_id' }

          it "does not generate any new tokens" do
            Songkick::OAuth2.should_not_receive(:random_string)
            get(params)
          end
        end
      end

      it "does not create a new Authorization" do
        get(params)
        Songkick::OAuth2::Model::Authorization.count.should == 1
      end

      it "keeps the code and access token on the Authorization" do
        get(params)
        authorization = Songkick::OAuth2::Model::Authorization.first
        authorization.code.should_not be_nil
        authorization.access_token_hash.should_not be_nil
      end
    end

    describe "with no parameters" do
      let(:params) { {} }

      it "renders an error page" do
        response = get(params)
        validate_response(response, 400, 'WAT')
      end
    end

    describe "with a redirect_uri and no client_id" do
      let(:params) { {'redirect_uri' => 'http://evilsite.com/callback'} }

      it "renders an error page" do
        response = get(params)
        validate_response(response, 400, 'WAT')
      end
    end

    describe "with a client_id and a bad redirect_uri" do
      let(:params) { {'redirect_uri' => 'http://evilsite.com/callback',
                      'client_id'    => @client.client_id} }

      it "redirects to the client's registered redirect_uri" do
        response = get(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=invalid_request&error_description=Missing+required+parameter+response_type'
      end
    end

    describe "with an invalid request" do
      before { params.delete('response_type') }

      it "redirects to the client's redirect_uri on error" do
        response = get(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=invalid_request&error_description=Missing+required+parameter+response_type'
      end

      describe "with a state parameter" do
        before { params['state'] = "Facebook\nmesses this\nup" }

        it "redirects to the client, including the state param" do
          response = get(params)
          response.code.to_i.should == 302
          response['location'].should == "https://client.example.com/cb?error=invalid_request&error_description=Missing+required+parameter+response_type&state=Facebook%0Amesses+this%0Aup"
        end
      end
    end
  end

  describe "authorization confirmation from the user" do
    let(:mock_auth) do
      mock = double Songkick::OAuth2::Provider::Authorization,
                    :redirect_uri    => 'http://example.com/',
                    :response_status => 302

      Songkick::OAuth2::Provider::Authorization.stub(:new).and_return(mock)
      mock
    end

    describe "without the user's permission" do
      before { params['allow'] = '' }

      it "does not grant access" do
        mock_auth.should_receive(:deny_access!)
        allow_or_deny(params)
      end

      it "redirects to the client with an error" do
        response = allow_or_deny(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=access_denied&error_description=The+user+denied+you+access'
      end
    end

    describe "with valid parameters and user permission" do
      before { Songkick::OAuth2.stub(:random_string).and_return('foo') }
      before { params['allow'] = '1' }

      describe "for code requests" do
        it "grants access" do
          mock_auth.should_receive(:grant_access!)
          allow_or_deny(params)
        end

        it "redirects to the client with an authorization code" do
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo'
        end

        it "passes the state parameter through" do
          params['state'] = 'illinois'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&state=illinois'
        end

        it "passes the scope parameter through" do
          params['scope'] = 'foo bar'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&scope=foo+bar'
        end
      end

      describe "for token requests" do
        before { params['response_type'] = 'token' }

        it "grants access" do
          mock_auth.should_receive(:grant_access!)
          allow_or_deny(params)
        end

        it "redirects to the client with an access token" do
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=foo&expires_in=10800'
        end

        it "passes the state parameter through" do
          params['state'] = 'illinois'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=foo&expires_in=10800&state=illinois'
        end

        it "passes the scope parameter through" do
          params['scope'] = 'foo bar'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb#access_token=foo&expires_in=10800&scope=foo+bar'
        end
      end

      describe "for code_and_token requests" do
        before { params['response_type'] = 'code_and_token' }

        it "grants access" do
          mock_auth.should_receive(:grant_access!)
          allow_or_deny(params)
        end

        it "redirects to the client with an access token" do
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo#access_token=foo&expires_in=10800'
        end

        it "passes the state parameter through" do
          params['state'] = 'illinois'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo&state=illinois#access_token=foo&expires_in=10800'
        end

        it "passes the scope parameter through" do
          params['scope'] = 'foo bar'
          response = allow_or_deny(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?code=foo#access_token=foo&expires_in=10800&scope=foo+bar'
        end
      end
    end
  end

  describe "access token request" do
    before do
      @client = Factory(:client)
      @authorization = create_authorization(
          :owner      => @owner,
          :client     => @client,
          :code       => 'a_fake_code',
          :expires_at => 3.hours.from_now)
    end

    let(:auth_params)  { { 'client_id'     => @client.client_id,
                           'client_secret' => @client.client_secret }
                       }

    describe "using authorization_code request" do
      let(:query_params) { { 'client_id'    => @client.client_id,
                             'grant_type'   => 'authorization_code',
                             'code'         => @authorization.code,
                             'redirect_uri' => @client.redirect_uri }
                         }

      let(:params) { auth_params.merge(query_params) }

      describe "with valid parameters" do
        it "does not respond to GET" do
          Songkick::OAuth2::Provider::Authorization.should_not_receive(:new)
          params.delete('client_secret')
          response = get(params)
          validate_json_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Bad request: must be a POST request'
          )
        end

        it "does not allow client credentials to be passed in the query string" do
          Songkick::OAuth2::Provider::Authorization.should_not_receive(:new)
          query_string = {'client_id' => params.delete('client_id'), 'client_secret' => params.delete('client_secret')}
          response = post(params, query_string)
          validate_json_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Bad request: must not send client credentials in the URI'
          )
        end

        describe "enforcing SSL" do
          before { Songkick::OAuth2::Provider.enforce_ssl = true }

          it "does not allow non-SSL requests" do
            response = get(params)
            validate_json_response(response, 400,
              'error'             => 'invalid_request',
              'error_description' => 'Bad request: must make requests using HTTPS'
            )
          end
        end

        it "creates a Token when using Basic Auth" do
          token = mock_request(Songkick::OAuth2::Provider::Exchange, :response_body => 'Hello')
          Songkick::OAuth2::Provider::Exchange.should_receive(:new).with(@owner, params, nil).and_return(token)
          post_basic_auth(auth_params, query_params)
        end

        it "creates a Token when passing params in the POST body" do
          token = mock_request(Songkick::OAuth2::Provider::Exchange, :response_body => 'Hello')
          Songkick::OAuth2::Provider::Exchange.should_receive(:new).with(@owner, params, nil).and_return(token)
          post(params)
        end

        it "returns a successful response" do
          Songkick::OAuth2.stub(:random_string).and_return('random_access_token')
          response = post_basic_auth(auth_params, query_params)
          validate_json_response(response, 200, 'access_token' => 'random_access_token', 'expires_in' => 10800)
        end

        describe "with a scope parameter" do
          before do
            @authorization.update_attribute(:scope, 'foo bar')
          end

          it "passes the scope back in the success response" do
            Songkick::OAuth2.stub(:random_string).and_return('random_access_token')
            response = post_basic_auth(auth_params, query_params)
            validate_json_response(response, 200,
              'access_token'  => 'random_access_token',
              'scope'         => 'foo bar',
              'expires_in'    => 10800
            )
          end
        end
      end

      describe "with invalid parameters" do
        before { query_params.delete('code') }

        it "returns an error response" do
          response = post_basic_auth(auth_params, query_params)
          validate_json_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Missing required parameter code'
          )
        end
      end

      describe "with mismatched client_id in POST params and Basic Auth params" do
        before { query_params['client_id'] = 'foo' }

        it "returns an error response" do
          response = post_basic_auth(auth_params, query_params)
          validate_json_response(response, 400,
            'error'             => 'invalid_request',
            'error_description' => 'Bad request: client_id from Basic Auth and request body do not match'
          )
        end
      end

      describe "when there is an Authorization with code and token" do
        before do
          @authorization.update_attributes(:code => 'pending_code', :access_token => 'working_token')
          Songkick::OAuth2.stub(:random_string).and_return('random_access_token')
        end

        it "returns a new access token" do
          response = post(params)
          validate_json_response(response, 200,
            'access_token' => 'random_access_token',
            'expires_in'   => 10800
          )
        end

        it "exchanges the code for the new token on the existing Authorization" do
          post(params)
          @authorization.reload
          @authorization.code.should be_nil
          @authorization.access_token_hash.should == Songkick::OAuth2.hashify('random_access_token')
        end
      end
    end
  end

  describe "protected resource request" do
    before do
      @authorization = create_authorization(
        :owner        => @owner,
        :client       => @client,
        :access_token => 'magic-key',
        :scope        => 'profile')
    end

    shared_examples_for "protected resource" do
      it "creates an AccessToken response" do
        mock_token = double(Songkick::OAuth2::Provider::AccessToken)
        mock_token.should_receive(:response_headers).and_return({})
        mock_token.should_receive(:response_status).and_return(200)
        mock_token.should_receive(:valid?).and_return(true)
        Songkick::OAuth2::Provider::AccessToken.should_receive(:new).with(TestApp::User['Bob'], ['profile'], 'magic-key', nil).and_return(mock_token)
        request('/user_profile', 'oauth_token' => 'magic-key')
      end

      it "allows access when the key is passed" do
        response = request('/user_profile', 'oauth_token' => 'magic-key')
        JSON.parse(response.body)['data'].should == 'Top secret'
        response.code.to_i.should == 200
      end

      it "blocks access when the wrong key is passed" do
        response = request('/user_profile', 'oauth_token' => 'is-the-password-books')
        JSON.parse(response.body)['data'].should == 'No soup for you'
        response.code.to_i.should == 401
        response['WWW-Authenticate'].should == "OAuth realm='Demo App', error='invalid_token'"
      end

      it "blocks access when the no key is passed" do
        response = request('/user_profile')
        JSON.parse(response.body)['data'].should == 'No soup for you'
        response.code.to_i.should == 401
        response['WWW-Authenticate'].should == "OAuth realm='Demo App'"
      end

      describe "enforcing SSL" do
        before { Songkick::OAuth2::Provider.enforce_ssl = true }

        let(:authorization) do
          Songkick::OAuth2::Model::Authorization.find_by_access_token_hash(Songkick::OAuth2.hashify('magic-key'))
        end

        it "blocks access when not using HTTPS" do
          response = request('/user_profile', 'oauth_token' => 'magic-key')
          JSON.parse(response.body)['data'].should == 'No soup for you'
          response.code.to_i.should == 401
          response['WWW-Authenticate'].should == "OAuth realm='Demo App', error='invalid_request'"
        end

        it "destroys the access token since it's been leaked" do
          authorization.access_token_hash.should == Songkick::OAuth2.hashify('magic-key')
          request('/user_profile', 'oauth_token' => 'magic-key')
          authorization.reload
          authorization.access_token_hash.should be_nil
        end

        it "keeps the access token if the wrong key is passed" do
          authorization.access_token_hash.should == Songkick::OAuth2.hashify('magic-key')
          request('/user_profile', 'oauth_token' => 'is-the-password-books')
          authorization.reload
          authorization.access_token_hash.should == Songkick::OAuth2.hashify('magic-key')
        end
      end
    end

    describe "for header-based requests" do
      def request(path, params = {})
        access_token = params.delete('oauth_token')
        http   = Net::HTTP.new('localhost', RequestHelpers::SERVER_PORT)
        qs     = params.map { |k,v| "#{ CGI.escape k.to_s }=#{ CGI.escape v.to_s }" }.join('&')
        header = {'Authorization' => "OAuth #{access_token}"}
        http.request_get(path + '?' + qs, header)
      end

      it_should_behave_like "protected resource"
    end

    describe "for GET requests" do
      def request(path, params = {})
        qs  = params.map { |k,v| "#{ CGI.escape k.to_s }=#{ CGI.escape v.to_s }" }.join('&')
        uri = URI.parse("http://localhost:#{RequestHelpers::SERVER_PORT}" + path + '?' + qs)
        Net::HTTP.get_response(uri)
      end

      it_should_behave_like "protected resource"
    end

    describe "for POST requests" do
      def request(path, params = {})
        Net::HTTP.post_form(URI.parse("http://localhost:#{RequestHelpers::SERVER_PORT}" + path), params)
      end

      it_should_behave_like "protected resource"
    end
  end
end

