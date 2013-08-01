require 'spec_helper'

describe Songkick::OAuth2::Model::Helpers do
  subject { Songkick::OAuth2::Model::Helpers }

  describe '.count' do
    let(:owner) { Factory(:owner) }

    before do
      3.times { Factory(:client, :owner => owner) }
    end

    context 'when conditions are not passed' do
      it 'returns count of total rows' do
        subject.count(owner.oauth2_clients).should == 3
      end
    end

    context 'when conditions are passed' do
      it 'returns count of rows satisfying supplied conditions' do
        subject.count(Songkick::OAuth2::Model::Client, :client_id => Songkick::OAuth2::Model::Client.first.client_id).should == 1
      end
    end
  end
end

