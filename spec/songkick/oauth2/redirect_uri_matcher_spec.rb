require 'spec_helper'

describe Songkick::OAuth2::RedirectURIMatcher do

  subject { described_class }
  let(:param_uri) { 'http://im.a.uri' }

  context 'when client and uri are the same' do
    let(:client_uri) { 'http://im.a.uri' }

    example do
      expect(subject.match?(client_uri, param_uri)).to be_truthy
    end
  end

  context 'when client is a pure wildcard' do
    let(:client_uri) { '*' }

    example do
      expect(subject.match?(client_uri, param_uri)).to be_truthy
    end
  end

  context 'when client is a wildcard uri' do
    let(:client_uri) { '*.uri' }

    example do
      expect(subject.match?(client_uri, param_uri)).to be_truthy
    end
  end

  context "when client is a wildcard but doesn't match" do
    let(:client_uri) { '*.not-a-uri' }

    example do
      expect(subject.match?(client_uri, param_uri)).to be_falsey
    end
  end

end
