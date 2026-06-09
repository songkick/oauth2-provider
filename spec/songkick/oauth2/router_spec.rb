require 'spec_helper'
require 'base64'

describe Songkick::OAuth2::Router do
  describe '.parse' do
    it 'does not require logging-only request fields on request-like objects' do
      request = double(
        'request',
        params: { 'grant_type' => 'assertion', 'client_id' => 'abc' },
        post?: true,
        ssl?: true,
        GET: {},
        env: {}
      )

      result = Songkick::OAuth2::Router.parse(nil, request)
      expect(result).to be_a(Songkick::OAuth2::Provider::Exchange)
    end

    it 'uses request params directly when request object is provided' do
      request = double(
        'request',
        params: { 'grant_type' => 'assertion', 'client_id' => 'abc' },
        post?: true,
        request_method: 'POST',
        content_type: 'application/x-www-form-urlencoded',
        ssl?: true,
        GET: {},
        env: {}
      )

      result = Songkick::OAuth2::Router.parse(nil, request)
      expect(result).to be_a(Songkick::OAuth2::Provider::Exchange)
    end

    it 'falls back to authorization when grant_type missing' do
      request = double(
        'request',
        params: { 'client_id' => 'abc' },
        post?: true,
        request_method: 'POST',
        content_type: 'application/x-www-form-urlencoded',
        ssl?: true,
        GET: {},
        env: {}
      )

      result = Songkick::OAuth2::Router.parse(nil, request)
      expect(result).to be_a(Songkick::OAuth2::Provider::Authorization)
    end

    it 'still supports raw rack env parsing' do
      env = Rack::MockRequest.env_for(
        '/authorize',
        method: 'POST',
        input: 'grant_type=assertion&client_id=abc'
      )
      env['REQUEST_URI'] = '/authorize'
      env['RAW_POST_DATA'] = 'grant_type=assertion&client_id=abc'

      result = Songkick::OAuth2::Router.parse(nil, env)
      expect(result).to be_a(Songkick::OAuth2::Provider::Exchange)
    end

    it 'returns exchange with request mismatch error when basic auth and body client_id differ' do
      request = double(
        'request',
        params: {
          'grant_type' => 'password',
          'client_id' => 'body-client',
          'client_secret' => 'body-secret'
        },
        post?: true,
        request_method: 'POST',
        content_type: 'application/x-www-form-urlencoded',
        ssl?: true,
        GET: {},
        env: {
          'HTTP_AUTHORIZATION' => "Basic #{Base64.strict_encode64('basic-client:basic-secret')}"
        }
      )

      result = Songkick::OAuth2::Router.parse(nil, request)
      expect(result).to be_a(Songkick::OAuth2::Provider::Exchange)
      expect(result).not_to be_valid
      expect(result.error).to eq('invalid_request')
      expect(result.error_description).to include('client_id from Basic Auth and request body do not match')
    end

    it 'returns exchange with method error when grant_type request is not POST' do
      request = double(
        'request',
        params: { 'grant_type' => 'assertion', 'client_id' => 'abc' },
        post?: false,
        request_method: 'GET',
        content_type: 'application/x-www-form-urlencoded',
        ssl?: true,
        GET: {},
        env: {}
      )

      result = Songkick::OAuth2::Router.parse(nil, request)
      expect(result).to be_a(Songkick::OAuth2::Provider::Exchange)
      expect(result).not_to be_valid
      expect(result.error).to eq('invalid_request')
      expect(result.error_description).to include('must be a POST request')
    end
  end
end
