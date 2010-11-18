require 'rack'

module OAuth2
  class Rack
    
    def self.request(env)
      params = ::Rack::Request.new(env).params
      Provider::Authorization.new(params)
    end
    
  end
end

