require 'base64'

module OAuth2
  class Router
    
    def self.auth_params(request, params = nil)
      return {} unless basic = request.env['HTTP_AUTHORIZATION']
      parts = basic.split(/\s+/)
      username, password = Base64.decode64(parts.last).split(':')
      {'client_id' => username, 'client_secret' => password}
    end
    
    def self.transport_error(request)
      uri = URI.parse(request.url)
      
      if Provider.mode != Provider::MODE_DEVELOPMENT and not uri.is_a?(URI::HTTPS)
        return Provider::Error.new("must make requests using HTTPS")
      end
    end
    
    def self.parse(resource_owner, request, params = nil)
      if error = transport_error(request)
        return error
      end
      
      params ||= request.params
      auth     = auth_params(request, params)
      
      if auth['client_id'] and auth['client_id'] != params['client_id']
        return Provider::Error.new("client_id from Basic Auth and request body do not match")
      end
      
      params = params.merge(auth)
      
      if params['grant_type']
        request.post? ?
            Provider::Exchange.new(resource_owner, params) :
            Provider::Error.new("should be a POST request")
      else
        Provider::Authorization.new(resource_owner, params)
      end
    end
    
    def self.access_token(resource_owner, scopes, request, params = nil)
      params ||= request.params
      header = request.env['HTTP_AUTHORIZATION']
      
      access_token = header && header =~ /^OAuth\s+/ ?
                     header.gsub(/^OAuth\s+/, '') :
                     params['oauth_token']
      
      Provider::AccessToken.new(resource_owner,
                                scopes,
                                access_token,
                                transport_error(request))
    end
    
  end
end

