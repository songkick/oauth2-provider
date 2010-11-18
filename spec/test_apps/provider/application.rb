require 'sinatra'

module TestApp
  class Provider < Sinatra::Base
    
    def self.start(port)
      Thread.new do
        Rack::Handler.get('thin').run(new, :Port => port) do |server|
          @server = server
        end
      end
      sleep 0.2 until @server
    end
    
    def self.stop
      @server.stop if @server
      @server = nil
    end
    
    set :views, File.dirname(__FILE__) + '/views'
    
    get '/authorize' do
      request = OAuth2::Rack.request(env)
      redirect request.redirect_uri unless request.valid?
      @client = request.client
      erb :authorize
    end
    
  end
end

