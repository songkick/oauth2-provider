require 'sinatra'
require File.expand_path('../../helper', __FILE__)

module TestApp
  class Provider < Sinatra::Base

    extend Helper::RackRunner

    Songkick::OAuth2::Provider.realm = 'Demo App'

    set :views, File.dirname(__FILE__) + '/views'

    def handle_authorize
      @oauth2 = Songkick::OAuth2::Provider.parse(User['Bob'], env)
      redirect(@oauth2.redirect_uri, @oauth2.response_status) if @oauth2.redirect?

      headers @oauth2.response_headers
      status  @oauth2.response_status

      if body = @oauth2.response_body
        body
      elsif @oauth2.valid?
        erb(:authorize)
      else
        'WAT'
      end
    end

    def protect_resource_for(user = nil, scopes = [])
      access_token = Songkick::OAuth2::Provider.access_token(user, scopes, env)
      headers access_token.response_headers
      status  access_token.response_status
      yield access_token
    end

    def serve_protected_resource
      @user = User['Bob']
      protect_resource_for(@user, ['profile']) do |auth|
        if auth.valid?
          JSON.unparse('data' => 'Top secret')
        else
          JSON.unparse('data' => 'No soup for you')
        end
      end
    end

    [:get, :post].each do |method|
      __send__(method, '/authorize') { handle_authorize }
    end

    post '/allow' do
      @user = User['bob']
      @oauth2 = Songkick::OAuth2::Provider::Authorization.new(@user, params)
      if params['allow'] == '1'
        @oauth2.grant_access! :duration => 3.hours
      else
        @oauth2.deny_access!
      end
      redirect @oauth2.redirect_uri, @oauth2.response_status
    end

    [:get, :post].each do |method|
      __send__(method, '/user_profile') { serve_protected_resource }
    end

  end
end

