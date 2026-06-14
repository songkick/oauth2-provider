module Songkick
  module OAuth2
    class Provider

      class Exchange
        attr_reader :client, :error, :error_description

        REQUIRED_PARAMS    = [CLIENT_ID, CLIENT_SECRET, GRANT_TYPE]
        VALID_GRANT_TYPES  = [AUTHORIZATION_CODE, PASSWORD, ASSERTION, REFRESH_TOKEN]

        REQUIRED_PASSWORD_PARAMS  = [USERNAME, PASSWORD]
        REQUIRED_ASSERTION_PARAMS = [ASSERTION_TYPE, ASSERTION]

        RESPONSE_HEADERS = {
          'Cache-Control' => 'no-store',
          'Content-Type'  => 'application/json'
        }

        def initialize(resource_owner, params, transport_error = nil)
          @params          = params
          @scope           = params[SCOPE]
          @grant_type      = @params[GRANT_TYPE]
          @resource_owner  = resource_owner

          @transport_error = transport_error

          oauth_debug_log('exchange.initialize', {
            grant_type: @grant_type,
            params_keys: @params.keys.sort,
            assertion_type: @params[ASSERTION_TYPE],
            has_assertion: @params.key?(ASSERTION)
          })
          validate!
        end

        def owner
          @authorization && @authorization.owner
        end

        def redirect?
          false
        end

        def response_body
          return jsonize(ERROR, ERROR_DESCRIPTION) unless valid?
          update_authorization

          response = {}
          [ACCESS_TOKEN, REFRESH_TOKEN, SCOPE].each do |key|
            value = @authorization.__send__(key)
            response[key] = value if value
          end
          if expiry = @authorization.expires_in
            response[EXPIRES_IN] = expiry
          end

          JSON.unparse(response)
        end

        def response_headers
          RESPONSE_HEADERS
        end

        def response_status
          valid? ? 200 : 400
        end

        def scopes
          scopes = @scope ? @scope.split(/\s+/).delete_if { |s| s.empty? } : []
          Set.new(scopes)
        end

        def update_authorization
          return if not valid? or @already_updated
          @authorization.exchange!
          @already_updated = true
        end

        def valid?
          @error.nil?
        end

      private

        def jsonize(*ivars)
          hash = {}
          ivars.each { |key| hash[key] = instance_variable_get("@#{key}") }
          JSON.unparse(hash)
        end

        def validate!
          if @transport_error
            set_error(@transport_error.error, @transport_error.error_description, 'exchange.transport_error')
            return
          end

          validate_required_params

          return if @error
          validate_client

          unless VALID_GRANT_TYPES.include?(@grant_type)
            set_error(
              UNSUPPORTED_GRANT_TYPE,
              "The grant type #{@grant_type} is not recognized",
              'exchange.unsupported_grant_type'
            )
          end
          return if @error

          __send__("validate_#{@grant_type}")
          validate_scope
          oauth_debug_log('exchange.validate.complete', {
            valid: @error.nil?,
            error: @error,
            error_description: @error_description
          })
        end

        def validate_required_params
          REQUIRED_PARAMS.each do |param|
            next if @params.has_key?(param)
            set_error(
              INVALID_REQUEST,
              "Missing required parameter #{param}",
              "exchange.required_param_missing.#{param}"
            )
          end
        end

        def validate_client
          @client = Model::Client.find_by_client_id(@params[CLIENT_ID])
          unless @client
            set_error(
              INVALID_CLIENT,
              "Unknown client ID #{@params[CLIENT_ID]}",
              'exchange.client_unknown'
            )
          end

          if @client and not @client.valid_client_secret?(@params[CLIENT_SECRET])
            set_error(
              INVALID_CLIENT,
              'Parameter client_secret does not match',
              'exchange.client_secret_mismatch'
            )
          end
        end

        def validate_scope
          if @authorization and not @authorization.in_scope?(scopes)
            set_error(
              INVALID_SCOPE,
              'The request scope was never granted by the user',
              'exchange.scope_not_granted'
            )
          end
        end

        def validate_authorization_code
          unless @params[CODE]
            set_error(
              INVALID_REQUEST,
              "Missing required parameter code",
              'exchange.authorization_code_missing'
            )
          end

          if @client.redirect_uri and !@client.redirect_uri.split(';').include?(@params[REDIRECT_URI])
            set_error(
              REDIRECT_MISMATCH,
              "Parameter redirect_uri does not match registered URI",
              'exchange.redirect_uri_mismatch'
            )
          end

          unless @params.has_key?(REDIRECT_URI)
            set_error(
              INVALID_REQUEST,
              "Missing required parameter redirect_uri",
              'exchange.redirect_uri_missing'
            )
          end

          return if @error

          @authorization = @client.authorizations.find_by_code(@params[CODE])
          validate_authorization
        end

        def validate_password
          REQUIRED_PASSWORD_PARAMS.each do |param|
            next if @params.has_key?(param)
            set_error(
              INVALID_REQUEST,
              "Missing required parameter #{param}",
              "exchange.password_param_missing.#{param}"
            )
          end

          return if @error

          @authorization = Provider.handle_password(@client, @params[USERNAME], @params[PASSWORD], scopes)
          return validate_authorization if @authorization

          set_error(
            INVALID_GRANT,
            'The access grant you supplied is invalid',
            'exchange.password_grant_invalid'
          )
        end

        def validate_assertion
          REQUIRED_ASSERTION_PARAMS.each do |param|
            next if @params.has_key?(param)
            set_error(
              INVALID_REQUEST,
              "Missing required parameter #{param}",
              "exchange.assertion_param_missing.#{param}"
            )
          end

          if @params[ASSERTION_TYPE]
            uri = URI.parse(@params[ASSERTION_TYPE]) rescue nil
            unless uri and uri.absolute?
              set_error(
                INVALID_REQUEST,
                'Parameter assertion_type must be an absolute URI',
                'exchange.assertion_type_not_absolute_uri'
              )
            end
          end

          return if @error

          assertion = Assertion.new(@params)
          @authorization = Provider.handle_assertion(@client, assertion, scopes, @resource_owner)
          return validate_authorization if @authorization

          set_error(
            UNAUTHORIZED_CLIENT,
            'Client cannot use the given assertion type',
            'exchange.assertion_handler_rejected'
          )
        end

        def validate_refresh_token
          refresh_token_hash = Songkick::OAuth2.hashify(@params[REFRESH_TOKEN])
          @authorization = @client.authorizations.find_by_refresh_token_hash(refresh_token_hash)
          validate_authorization
        end

        def validate_authorization
          unless @authorization
            set_error(
              INVALID_GRANT,
              'The access grant you supplied is invalid',
              'exchange.authorization_missing'
            )
          end

          if @authorization and @authorization.expired?
            set_error(
              INVALID_GRANT,
              'The access grant you supplied is invalid',
              'exchange.authorization_expired'
            )
          end
        end

        def set_error(error, error_description, reason_code)
          @error = error
          @error_description = error_description
          oauth_debug_log('exchange.error', {
            reason_code: reason_code,
            error: error,
            error_description: error_description,
            grant_type: @grant_type
          })
        end

        def oauth_debug_log(event, payload)
          $stderr.puts("[oauth2-provider] #{event} #{payload.to_json}")
        rescue StandardError
          # best-effort diagnostics only
        end
      end

      class Assertion
        attr_reader :type, :value
        def initialize(params)
          @type  = params[ASSERTION_TYPE]
          @value = params[ASSERTION]
        end
      end

    end
  end
end
