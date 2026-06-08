require 'spec_helper'

describe Songkick::OAuth2::Router do
  describe '.parse' do
    it 'uses already-parsed params from request objects' do
      request = double(
        'request',
        params: { 'grant_type' => 'assertion' },
        post?: true,
        ssl?: true,
        GET: {},
        env: {}
      )

      parsed = Songkick::OAuth2::Router.parse(nil, request)
      expect(parsed).to be_a(Songkick::OAuth2::Provider::Exchange)
    end

    it 'still supports raw rack env inputs' do
      env = Rack::MockRequest.env_for(
        '/authorize',
        method: 'POST',
        input: 'grant_type=assertion'
      )
      env['REQUEST_URI'] = '/authorize'
      env['RAW_POST_DATA'] = 'grant_type=assertion'

      parsed = Songkick::OAuth2::Router.parse(nil, env)
      expect(parsed).to be_a(Songkick::OAuth2::Provider::Exchange)
    end
  end
end
