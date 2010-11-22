require 'rack'
require 'base64'

module OAuth2
  class Rack
    
    def self.request(env)
      request = ::Rack::Request.new(env)
      auth    = auth_params(request)
      params  = request.params
      
      params['grant_type'] ?
        Provider::Token.new(auth.merge(params)) :
        Provider::Authorization.new(params)
    end
    
    def self.auth_params(request)
      return {} unless basic = request.env['HTTP_AUTHORIZATION']
      parts = basic.split(/\s+/)
      username, password = Base64.decode64(parts.last).split(':')
      {'client_id' => username, 'client_secret' => password}
    end
    
  end
end

