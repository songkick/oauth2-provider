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
          request = request_or_request_from(env)
          params  = request.params
          auth    = auth_params(env_from(env))
          oauth_debug_log(
            'router.parse.ingress',
            {
              method: request_method_for_log(request),
              content_type: content_type_for_log(request),
              request_uri: request_uri_for_log(request, env),
              params_keys: params.keys.sort,
              grant_type: params[GRANT_TYPE],
              assertion_type: params[ASSERTION_TYPE],
              has_assertion: params.key?(ASSERTION),
              has_client_id: params.key?(CLIENT_ID),
              has_client_secret: params.key?(CLIENT_SECRET)
            }
          )

          if auth[CLIENT_ID] and auth[CLIENT_ID] != params[CLIENT_ID]
            error ||= Provider::Error.new("#{CLIENT_ID} from Basic Auth and request body do not match")
            oauth_debug_log(
              'router.parse.auth_mismatch',
              {
                body_client_id: params[CLIENT_ID],
                basic_auth_client_id: auth[CLIENT_ID]
              }
            )
          end

          params = params.merge(auth)
          oauth_debug_log(
            'router.parse.post_auth_merge',
            {
              params_keys: params.keys.sort,
              grant_type: params[GRANT_TYPE],
              has_transport_error: !error.nil?,
              transport_error: error&.error_description
            }
          )

          if params[GRANT_TYPE]
            error ||= Provider::Error.new('must be a POST request') unless request.post?
            oauth_debug_log(
              'router.parse.branch.exchange',
              {
                grant_type: params[GRANT_TYPE],
                method: request_method_for_log(request)
              }
            )
            Provider::Exchange.new(resource_owner, params, error)
          else
            oauth_debug_log(
              'router.parse.branch.authorization',
              {
                reason: 'missing_grant_type',
                params_keys: params.keys.sort
              }
            )
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

          header && header =~ /^OAuth\s+/ ?
              header.gsub(/^OAuth\s+/, '') :
              params[OAUTH_TOKEN]
        end

      private

        def request_or_request_from(env_or_request)
          env_or_request.respond_to?(:params) ? env_or_request : request_from(env_or_request)
        end

        def env_from(env_or_request)
          env_or_request.respond_to?(:env) ? env_or_request.env : env_or_request
        end

        def request_from(env_or_request)
          env = env_from(env_or_request)
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
          request = request_or_request_from(env)

          if Provider.enforce_ssl and not request.ssl?
            oauth_debug_log('router.transport_error', { reason: 'ssl_required' })
            Provider::Error.new('must make requests using HTTPS')
          elsif request.GET['client_secret']
            oauth_debug_log('router.transport_error', { reason: 'client_secret_in_uri' })
            Provider::Error.new('must not send client credentials in the URI')
          end
        end

        def oauth_debug_log(event, payload)
          $stderr.puts("[oauth2-provider] #{event} #{payload.to_json}")
        rescue StandardError
          # best-effort diagnostics only
        end

        def request_method_for_log(request)
          return request.request_method if request.respond_to?(:request_method)
          return 'POST' if request.respond_to?(:post?) && request.post?
          nil
        rescue StandardError
          nil
        end

        def content_type_for_log(request)
          return request.content_type if request.respond_to?(:content_type)
          nil
        rescue StandardError
          nil
        end

        def request_uri_for_log(request, env_or_request)
          request_env = request.respond_to?(:env) ? request.env : nil
          return request_env['REQUEST_URI'] if request_env && request_env['REQUEST_URI']

          env = env_from(env_or_request)
          env['REQUEST_URI']
        rescue StandardError
          nil
        end
      end

    end
  end
end

