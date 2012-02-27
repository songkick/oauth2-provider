require 'base64'

module OAuth2
  class Router
    
    def self.auth_params(request, params = nil)
      return {} unless basic = request.env['HTTP_AUTHORIZATION']
      parts = basic.split(/\s+/)
      username, password = Base64.decode64(parts.last).split(':')
      {CLIENT_ID => username, CLIENT_SECRET => password}
    end
    
    def self.detect_transport_error(request)
      uri = URI.parse(request.url)
      
      if Provider.enforce_ssl and not uri.is_a?(URI::HTTPS)
        Provider::Error.new("must make requests using HTTPS")
      end
    end
    
    def self.parse(resource_owner, request, params = nil)
      error = detect_transport_error(request)
      
      params ||= request.params
      auth     = auth_params(request, params)
      
      if auth[CLIENT_ID] and auth[CLIENT_ID] != params[CLIENT_ID]
        error ||= Provider::Error.new("#{CLIENT_ID} from Basic Auth and request body do not match")
      end
      
      params = params.merge(auth)
      
      if params[GRANT_TYPE]
        error ||= Provider::Error.new('must be a POST request') unless request.post?
        Provider::Exchange.new(resource_owner, params, error)
      else
        Provider::Authorization.new(resource_owner, params, error)
      end
    end
    
    def self.access_token(resource_owner, scopes, request, params = nil)
      params ||= request.params
      header = request.env['HTTP_AUTHORIZATION']
      
      access_token = header && header =~ /^OAuth\s+/ ?
                     header.gsub(/^OAuth\s+/, '') :
                     params[OAUTH_TOKEN]
      
      Provider::AccessToken.new(resource_owner,
                                scopes,
                                access_token,
                                detect_transport_error(request))
    end
    
  end
end

