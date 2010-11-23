require 'spec_helper'

describe OAuth2::Model::Client do
  before do
    @client = Factory(:client)
    @owner  = Factory(:owner)
    Factory(:authorization, :client => @client, :owner => @owner)
  end
  
  it "destroys its authorizations on destroy" do
    @client.destroy
    OAuth2::Model::Authorization.count.should be_zero
  end
end

