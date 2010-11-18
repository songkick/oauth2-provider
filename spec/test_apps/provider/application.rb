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
    end
    
    get '/authorize' do
      request = OAuth2::Rack.request(env)
      redirect request.redirect_url if request.should_redirect?
      'OK'
    end
    
  end
end

