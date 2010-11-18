require 'spec_helper'

describe OAuth2::Provider do
  include OAuth2
  
  before { TestApp::Provider.start(8000) }
  after  { TestApp::Provider.stop }
  
  let(:provider_uri) { 'http://localhost:8000/authorize' }
  
  before do
    @client = Model::Client.create(:client_id => 's6BhdRkqt3', :redirect_uri => 'https://client.example.com/cb')
  end
  
  after do
    @client.destroy
  end
  
  def get(query_params)
    qs  = params.map { |k,v| "#{ CGI.escape k.to_s }=#{ CGI.escape v.to_s }" }.join('&')
    uri = URI.parse(provider_uri + '?' + qs)
    Net::HTTP.get_response(uri)
  end
  
  describe "authorization request" do
    let(:params) { { :response_type => 'code',
                     :client_id     => 's6BhdRkqt3',
                     :redirect_uri  => 'https://client.example.com/cb' }
                 }
    
    describe "with valid parameters" do
      it "creates an authorization" do
        auth = mock(Provider::Authorization)
        Provider::Authorization.should_receive(:new).with(params).and_return(auth)
        auth.should_receive(:valid?).and_return(true)
        response = get(params)
        response.code.to_i.should == 200
      end
    end
    
    describe "with an invalid request" do
      before { params.delete(:response_type) }
      
      it "redirects to the client's redirect_uri on error" do
        response = get(params)
        response.code.to_i.should == 302
        response['location'].should == 'https://client.example.com/cb?error=invalid_request&error_description=Missing+required+parameter+response_type'
      end
      
      describe "with a state parameter" do
        before { params[:state] = 'foo' }
      
        it "redirects to the client, including the state param" do
          response = get(params)
          response.code.to_i.should == 302
          response['location'].should == 'https://client.example.com/cb?error=invalid_request&error_description=Missing+required+parameter+response_type&state=foo'
        end
      end
    end
  end
end

