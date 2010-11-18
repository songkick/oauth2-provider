require 'spec_helper'

describe OAuth2::Provider do
  before { TestApp::Provider.start(8000) }
  after  { TestApp::Provider.stop }
  
  let(:provider_uri) { 'http://localhost:8000/authorize' }
  
  include OAuth2
  
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
    
    it "creates an authorization" do
      Provider::Authorization.should_receive(:new).with(params)
      get(params)
    end
  end
end

