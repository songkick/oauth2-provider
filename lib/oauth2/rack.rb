require 'rack'
require 'base64'

module OAuth2
  class Rack
    
    def self.auth_params(request)
      return {} unless basic = request.env['HTTP_AUTHORIZATION']
      parts = basic.split(/\s+/)
      username, password = Base64.decode64(parts.last).split(':')
      {'client_id' => username, 'client_secret' => password}
    end
    
    def self.parse(request)
      params  = request.params
      auth    = auth_params(request)
      
      if auth['client_id'] and auth['client_id'] != params['client_id']
        return Provider::Error.new("client_id from Basic Auth and request body do not match")
      end
      
      params = params.merge(auth)
      
      if params['grant_type']
        request.post? ? Provider::Token.new(params) : Provider::Error.new
      else
        Provider::Authorization.new(params)
      end
    end
    
    def self.access_token(request)
      header = request.env['HTTP_AUTHORIZATION']
      if header
        header.gsub(/^OAuth\s+/, '')
      else
        request.params['access_token']
      end
    end
    
  end
end

