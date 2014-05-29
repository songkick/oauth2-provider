module Songkick
  module OAuth2
    class Router

      # Public methods in the namespace take either Rack env objects, or Request
      # objects from Rails/Sinatra and an optional params hash which it then
      # coerces to Rack requests. This is for backward compatibility; originally
      # it only took request objects.

      class << self
        def parse(resource_owner, env)
          error   = detect_transport_error(env)
          request = request_from(env)
          params  = request.params
          auth    = auth_params(env)

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

        def access_token(resource_owner, scopes, env)
          access_token = access_token_from_request(env)
          Provider::AccessToken.new(resource_owner,
                                    scopes,
                                    access_token,
                                    detect_transport_error(env))
        end

        def access_token_from_request(env)
          request = request_from(env)
          params  = request.params
          header  = request.env['HTTP_AUTHORIZATION']

          header && header =~ /^(OAuth|Bearer)\s+/ ?
              header.gsub(/^(OAuth|Bearer)\s+/, '') :
              params[OAUTH_TOKEN]
        end

      private

        def request_from(env_or_request)
          env = env_or_request.respond_to?(:env) ? env_or_request.env : env_or_request
          env = Rack::MockRequest.env_for(env['REQUEST_URI'] || '', :input => env['RAW_POST_DATA']).merge(env)
          Rack::Request.new(env)
        end

        def auth_params(env)
          return {} unless basic = env['HTTP_AUTHORIZATION']
          parts = basic.split(/\s+/)
          username, password = Base64.decode64(parts.last).split(':')
          {CLIENT_ID => username, CLIENT_SECRET => password}
        end

        def detect_transport_error(env)
          request = request_from(env)

          if Provider.enforce_ssl and not request.ssl?
            Provider::Error.new('must make requests using HTTPS')
          elsif request.GET['client_secret']
            Provider::Error.new('must not send client credentials in the URI')
          end
        end
      end

    end
  end
end

