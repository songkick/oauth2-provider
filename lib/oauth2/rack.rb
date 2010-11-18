require 'rack'

module OAuth2
  class Rack
    
    def self.request(env)
      params = Hash[::Rack::Request.new(env).params.map { |k,v| [k.to_sym, v] }]
      Provider::Authorization.new(params)
    end
    
  end
end

