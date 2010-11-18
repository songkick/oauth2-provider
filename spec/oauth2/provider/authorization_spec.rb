require 'spec_helper'

describe OAuth2::Provider::Authorization do
  include OAuth2
  
  let(:authorization) { Provider::Authorization.new(params) }
  
  let(:params) { { :response_type => 'code',
                   :client_id     => 's6BhdRkqt3',
                   :redirect_uri  => 'https://client.example.com/cb' }
               }
  
  before do
    @client = Model::Client.create(:client_id    => 's6BhdRkqt3',
                                   :name         => 'Test client',
                                   :redirect_uri => 'https://client.example.com/cb')
  end
  
  after do
    @client.destroy
  end
  
  describe "with valid parameters" do
    it "is valid" do
      authorization.error.should be_nil
    end
  end
  
  describe "missing response_type" do
    before { params.delete(:response_type) }
    
    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter response_type"
    end
  end
  
  describe "with a bad response_type" do
    before { params[:response_type] = "no_such_type" }
    
    it "is invalid" do
      authorization.error.should == "unsupported_response_type"
      authorization.error_description.should == "Response type no_such_type is not supported"
    end
  end
  
  describe "missing client_id" do
    before { params.delete(:client_id) }
    
    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter client_id"
    end
  end
  
  describe "with an unknown client_id" do
    before { params[:client_id] = "unknown" }
    
    it "is invalid" do
      authorization.error.should == "invalid_client"
      authorization.error_description.should == "Unknown client ID unknown"
    end
  end
  
  describe "missing redirect_uri" do
    before { params.delete(:redirect_uri) }
    
    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter redirect_uri"
    end
  end
  
  describe "with a mismatched redirect_uri" do
    before { params[:redirect_uri] = "http://songkick.com" }
    
    it "is invalid" do
      authorization.error.should == "redirect_uri_mismatch"
      authorization.error_description.should == "Parameter redirect_uri does not match registered URI"
    end
  end
end

