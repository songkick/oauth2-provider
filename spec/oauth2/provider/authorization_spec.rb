require 'spec_helper'

describe OAuth2::Provider::Authorization do
  let(:authorization) { OAuth2::Provider::Authorization.new(params) }
  
  let(:params) { { :response_type => 'code',
                   :client_id     => 's6BhdRkqt3',
                   :redirect_uri  => 'https://client.example.com/cb' }
               }
  
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
  
  describe "missing response_type" do
    before { params.delete(:client_id) }
    
    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter client_id"
    end
  end
  
  describe "missing redirect_uri" do
    before { params.delete(:redirect_uri) }
    
    it "is invalid" do
      authorization.error.should == "invalid_request"
      authorization.error_description.should == "Missing required parameter redirect_uri"
    end
  end
end

