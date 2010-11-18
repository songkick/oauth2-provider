require 'spec_helper'

describe OAuth2::Provider do
  include OAuth2
  
  before { TestApp::Provider.start(8000) }
  after  { TestApp::Provider.stop }
  
  let(:authorization_uri) { 'http://localhost:8000/authorize' }
  let(:confirmation_uri)  { 'http://localhost:8000/allow' }
  
  let(:params) { { 'response_type' => 'code',
                   'client_id'     => 's6BhdRkqt3',
                   'redirect_uri'  => 'https://client.example.com/cb' }
               }
  
  before do
    @client = Model::Client.create(:client_id    => 's6BhdRkqt3',
                                   :name         => 'Test client',
                                   :redirect_uri => 'https://client.example.com/cb')
  end
  
  after do
    @client.destroy
  end
  
  def get(query_params)
    qs  = params.map { |k,v| "#{ URI.escape k.to_s }=#{ URI.escape v.to_s }" }.join('&')
    uri = URI.parse(authorization_uri + '?' + qs)
    Net::HTTP.get_response(uri)
  end
  
  def post(query_params)
    Net::HTTP.post_form(URI.parse(confirmation_uri), query_params)
  end
  
  describe "authorization request" do
    describe "with valid parameters" do
      it "creates an authorization" do
        auth = mock(Provider::Authorization)
        Provider::Authorization.should_receive(:new).with(params).and_return(auth)
        auth.should_receive(:valid?).and_return(true)
        auth.should_receive(:client).and_return(@client)
        auth.should_receive(:params).and_return({})
        get(params)
      end
      
      it "displays an authorization page" do
        response = get(params)
        response.code.to_i.should == 200
        response.body.should =~ /Do you want to allow Test client/
      end
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
    describe "without the user's permission" do
      before { params['allow'] = '' }
      
      it "redirects to the client with an error" do
        response = post(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=access_denied&error_description=The%20user%20denied%20you%20access'
      end
    end
    
    describe "with valid parameters and user permission" do
      before { params['allow'] = '1' }
      
      it "redirects to the client with an authorization code" do
        OAuth2.stub(:random_string).and_return('foo')
        response = post(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?code=foo&expires_in=3600'
      end
    end
  end
end

