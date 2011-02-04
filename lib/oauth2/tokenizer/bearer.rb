module OAuth2
  module Tokenizer
    
    class Bearer
      def token_type
        'bearer'
      end
      
      def access_token(resource_owner, scopes, request, params = nil)
        params ||= request.params
        header = request.env['HTTP_AUTHORIZATION']
        
        access_token = header && header =~ /^OAuth2\s+/ ?
                       header.gsub(/^OAuth2\s+/, '') :
                       params[OAUTH_TOKEN]
        
        Provider::AccessToken.new(resource_owner,
                                  scopes,
                                  access_token,
                                  Router.transport_error(request))
      end
    end
    
  end
end

