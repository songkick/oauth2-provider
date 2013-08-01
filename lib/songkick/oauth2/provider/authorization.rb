module Songkick
  module OAuth2
    class Provider

      class Authorization
        attr_reader :owner, :client,
                    :code, :access_token,
                    :expires_in, :refresh_token,
                    :error, :error_description

        REQUIRED_PARAMS = [RESPONSE_TYPE, CLIENT_ID, REDIRECT_URI]
        VALID_PARAMS    = REQUIRED_PARAMS + [SCOPE, STATE]
        VALID_RESPONSES = [CODE, TOKEN, CODE_AND_TOKEN]

        def initialize(resource_owner, params, transport_error = nil)
          @owner  = resource_owner
          @params = params
          @scope  = params[SCOPE]
          @state  = params[STATE]

          @transport_error = transport_error

          validate!

          return unless @owner and not @error

          @model = @owner.oauth2_authorization_for(@client)
          return unless @model and @model.in_scope?(scopes) and not @model.expired?

          @authorized = true

          if @params[RESPONSE_TYPE] =~ /code/
            @code = @model.generate_code
          end

          if @params[RESPONSE_TYPE] =~ /token/
            @access_token = @model.generate_access_token
          end
        end

        def scopes
          scopes = @scope ? @scope.split(/\s+/).delete_if { |s| s.empty? } : []
          Set.new(scopes)
        end

        def unauthorized_scopes
          @model ? scopes.select { |s| not @model.in_scope?(s) } : scopes
        end

        def grant_access!(options = {})
          @model = Model::Authorization.for(@owner, @client,
            :response_type => @params[RESPONSE_TYPE],
            :scope         => @scope,
            :duration      => options[:duration])

          @code          = @model.code
          @access_token  = @model.access_token
          @refresh_token = @model.refresh_token
          @expires_in    = @model.expires_in

          unless @params[RESPONSE_TYPE] == CODE
            @expires_in = @model.expires_in
          end

          @authorized = true
        end

        def deny_access!
          @code = @access_token = @refresh_token = nil
          @error = ACCESS_DENIED
          @error_description = "The user denied you access"
        end

        def params
          params = {}
          VALID_PARAMS.each { |key| params[key] = @params[key] if @params.has_key?(key) }
          params
        end

        def redirect?
          @client and (@authorized or not valid?)
        end

        def redirect_uri
          return nil unless @client
          base_redirect_uri = @client.redirect_uri
          q = (base_redirect_uri =~ /\?/) ? '&' : '?'

          if not valid?
            query = to_query_string(ERROR, ERROR_DESCRIPTION, STATE)
            "#{ base_redirect_uri }#{ q }#{ query }"

          elsif @params[RESPONSE_TYPE] == CODE_AND_TOKEN
            query    = to_query_string(CODE, STATE)
            fragment = to_query_string(ACCESS_TOKEN, EXPIRES_IN, SCOPE)
            "#{ base_redirect_uri }#{ query.empty? ? '' : q + query }##{ fragment }"

          elsif @params[RESPONSE_TYPE] == TOKEN
            fragment = to_query_string(ACCESS_TOKEN, EXPIRES_IN, SCOPE, STATE)
            "#{ base_redirect_uri }##{ fragment }"

          else
            query = to_query_string(CODE, SCOPE, STATE)
            "#{ base_redirect_uri }#{ q }#{ query }"
          end
        end

        def response_body
          warn "Songkick::OAuth2::Provider::Authorization no longer returns a response body "+
               "when the request is invalid. You should call valid? to determine "+
               "whether to render your login page or an error page."
          nil
        end

        def response_headers
          redirect? ? {} : {'Cache-Control' => 'no-store'}
        end

        def response_status
          return 302 if redirect?
          return 200 if valid?
          @client ? 302 : 400
        end

        def valid?
          @error.nil?
        end

      private

        def validate!
          if @transport_error
            @error = @transport_error.error
            @error_description = @transport_error.error_description
            return
          end

          @client = @params[CLIENT_ID] && Model::Client.find_by_client_id(@params[CLIENT_ID])
          unless @client
            @error = INVALID_CLIENT
            @error_description = "Unknown client ID #{@params[CLIENT_ID]}"
          end

          REQUIRED_PARAMS.each do |param|
            next if @params.has_key?(param)
            @error = INVALID_REQUEST
            @error_description = "Missing required parameter #{param}"
          end
          return if @error

          [SCOPE, STATE].each do |param|
            next unless @params.has_key?(param)
            if @params[param] =~ /\r\n/
              @error = INVALID_REQUEST
              @error_description = "Illegal value for #{param} parameter"
            end
          end

          unless VALID_RESPONSES.include?(@params[RESPONSE_TYPE])
            @error = UNSUPPORTED_RESPONSE
            @error_description = "Response type #{@params[RESPONSE_TYPE]} is not supported"
          end

          @client = Model::Client.find_by_client_id(@params[CLIENT_ID])
          unless @client
            @error = INVALID_CLIENT
            @error_description = "Unknown client ID #{@params[CLIENT_ID]}"
          end

          if @client and @client.redirect_uri and @client.redirect_uri != @params[REDIRECT_URI]
            @error = REDIRECT_MISMATCH
            @error_description = "Parameter #{REDIRECT_URI} does not match registered URI"
          end
        end

        def to_query_string(*ivars)
          ivars.map { |key|
            value = instance_variable_get("@#{key}")
            value = value.join(' ') if Array === value
            value ? "#{ key }=#{ CGI.escape(value.to_s) }" : nil
          }.compact.join('&')
        end
      end

    end
  end
end

