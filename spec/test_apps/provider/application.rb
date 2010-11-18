require 'sinatra'

module TestApp
  class Provider < Sinatra::Base
    
    def self.start(port)
      Thread.new do
        Rack::Handler.get('thin').run(new, :Port => port) do |server|
          @server = server
        end
      end
      sleep 0.1 until @server
    end
    
    def self.stop
      @server.stop if @server
      @server = nil
      sleep 0.1 while EM.reactor_running?
    end
    
    set :views, File.dirname(__FILE__) + '/views'
    
    get '/authorize' do
      @request = OAuth2::Rack.request(env)
      redirect @request.redirect_uri unless @request.valid?
      erb :authorize
    end
    
    post '/allow' do
      @request = OAuth2::Provider::Authorization.new(params)
      if params['allow'] == '1'
        @request.grant_access!
      else
        @request.deny_access!
      end
      redirect @request.redirect_uri
    end
    
  end
end

