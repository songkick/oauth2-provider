require 'sinatra'

module TestApp
  class Provider < Sinatra::Base
    
    extend Helper::RackRunner
    
    set :views, File.dirname(__FILE__) + '/views'
    
    def handle_authorize
      @oauth2 = OAuth2::Provider.parse(request)
      redirect @oauth2.redirect_uri if @oauth2.redirect?
      
      headers @oauth2.response_headers
      status  @oauth2.response_status
      
      @oauth2.response_body || erb(:authorize)
    end
    
    def serve_protected_resource
      @user = User['Bob']
      @auth = OAuth2::Provider.access_token(request)
      if @user.grants_access?(@auth, 'profile')
        JSON.unparse('data' => 'Top secret')
      else
        JSON.unparse('data' => 'No soup for you')
      end
    end
    
    [:get, :post].each do |method|
      __send__(method, '/authorize') { handle_authorize }
    end
    
    post '/allow' do
      @oauth2 = OAuth2::Provider::Authorization.new(params)
      @user = User['bob']
      if params['allow'] == '1'
        @oauth2.grant_access!(@user)
      else
        @oauth2.deny_access!
      end
      redirect @oauth2.redirect_uri
    end
    
    [:get, :post].each do |method|
      __send__(method, '/user_profile') { serve_protected_resource }
    end
    
  end
end

