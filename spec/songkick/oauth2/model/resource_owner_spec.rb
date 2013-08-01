require 'spec_helper'

describe Songkick::OAuth2::Model::ResourceOwner do
  before do
    @owner  = Factory(:owner)
    @client = Factory(:client)
  end

  describe "#grant_access!" do
    it "raises an error when passed an invalid client argument" do
      lambda{ @owner.grant_access!('client') }.should raise_error(ArgumentError)
    end

    it "creates an authorization between the owner and the client" do
      authorization = Songkick::OAuth2::Model::Authorization.__send__(:new)
      Songkick::OAuth2::Model::Authorization.should_receive(:new).and_return(authorization)
      @owner.grant_access!(@client)
    end

    # This is hacky, but doubleing ActiveRecord turns out to get messy
    it "creates an Authorization" do
      Songkick::OAuth2::Model::Authorization.count.should == 0
      @owner.grant_access!(@client)
      Songkick::OAuth2::Model::Authorization.count.should == 1
    end

    it "returns the authorization" do
      @owner.grant_access!(@client).should be_kind_of(Songkick::OAuth2::Model::Authorization)
    end

    # This method must return the same owner object, since the assertion
    # handler may modify it -- either by changing its attributes or by extending
    # it with new methods. These changes must be returned to the app calling the
    # Provider interface.
    it "sets the receiver as the authorization's owner" do
      authorization = @owner.grant_access!(@client)
      authorization.owner.should be_equal(@owner)
    end

    it "sets the duration of the authorization" do
      authorization = @owner.grant_access!(@client, :duration => 5.hours)
      authorization.expires_at.to_i.should == (Time.now + 5.hours.to_i).to_i
    end
  end

  describe "when there is an existing authorization" do
    before do
      @authorization = create_authorization(:owner => @owner, :client => @client)
    end

    it "does not create a new one" do
      Songkick::OAuth2::Model::Authorization.should_not_receive(:new)
      @owner.grant_access!(@client)
    end

    it "updates the authorization with scopes" do
      @owner.grant_access!(@client, :scopes => ['foo', 'bar'])
      @authorization.reload
      @authorization.scopes.should == Set.new(['foo', 'bar'])
    end

    describe "with scopes" do
      before do
        @authorization.update_attribute(:scope, 'foo bar')
      end

      it "merges the new scopes with the existing ones" do
        @owner.grant_access!(@client, :scopes => ['qux'])
        @authorization.reload
        @authorization.scopes.should == Set.new(['foo', 'bar', 'qux'])
      end

      it "does not add duplicate scopes to the list" do
        @owner.grant_access!(@client, :scopes => ['qux'])
        @owner.grant_access!(@client, :scopes => ['qux'])
        @authorization.reload
        @authorization.scopes.should == Set.new(['foo', 'bar', 'qux'])
      end
    end
  end

  it "destroys its authorizations on destroy" do
    Songkick::OAuth2::Model::Authorization.for(@owner, @client)
    @owner.destroy
    Songkick::OAuth2::Model::Authorization.count.should be_zero
  end
end

