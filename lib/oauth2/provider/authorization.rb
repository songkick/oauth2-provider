module OAuth2
  class Provider
    
    class Authorization
      attr_reader :client, :code, :access_token,
                  :expires_in, :refresh_token,
                  :error, :error_description
      
      REQUIRED_PARAMS = %w[response_type client_id redirect_uri]
      VALID_PARAMS    = REQUIRED_PARAMS + %w[scope state]
      VALID_RESPONSES = %w[code token code_and_token]
      
      def initialize(resource_owner, params)
        @owner  = resource_owner
        @params = params
        @scope  = params['scope']
        @state  = params['state']
        
        validate!
        return unless @owner and not @error
        
        @model = Model::Authorization.for(@owner, @client)
        return unless @model and @model.in_scope?(scopes)
        
        @authorized = true
        @code = @model.code
      end
      
      def scopes
        @scope ? @scope.split(/\s+/).delete_if { |s| s.empty? } : []
      end
      
      def unauthorized_scopes
        @model ? scopes.select { |s| not @model.in_scope?(s) } : scopes
      end
      
      def grant_access!
        model = Model::Authorization.create_for_response_type(@params['response_type'],
          :owner  => @owner,
          :client => @client,
          :scope  => @scope)
        
        @code          = model.code
        @access_token  = model.access_token
        @refresh_token = model.refresh_token
        
        unless @params['response_type'] == 'code'
          @expires_in  = model.expires_in
        end
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
        
        if not valid?
          query = to_query_string(:error, :error_description, :state)
          "#{ base_redirect_uri }?#{ query }"
        
        elsif @params['response_type'] == 'code_and_token'
          query    = to_query_string(:code, :state)
          fragment = to_query_string(:access_token, :expires_in, :scope)
          "#{ base_redirect_uri }#{ query.empty? ? '' : '?' + query }##{ fragment }"
        
        elsif @params['response_type'] == 'token'
          fragment = to_query_string(:access_token, :expires_in, :scope, :state)
          "#{ base_redirect_uri }##{ fragment }"
        
        else
          query = to_query_string(:code, :scope, :state)
          "#{ base_redirect_uri }?#{ query }"
        end
      end
      
      def response_body
        return nil if @client and valid?
        JSON.unparse(
          'error'             => INVALID_REQUEST,
          'error_description' => 'This is not a valid OAuth request')
      end
      
      def response_headers
        valid? ? {} : Token::RESPONSE_HEADERS
      end
      
      def response_status
        return 200 if valid?
        @client ? 302 : 400
      end
      
      def valid?
        @error.nil?
      end
      
    private
      
      def validate!
        @client = @params['client_id'] && Model::Client.find_by_client_id(@params['client_id'])
        unless @client
          @error = INVALID_CLIENT
          @error_description = "Unknown client ID #{@params['client_id']}"
        end
        
        REQUIRED_PARAMS.each do |param|
          next if @params.has_key?(param)
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter #{param}"
        end
        return if @error
        
        unless VALID_RESPONSES.include?(@params['response_type'])
          @error = UNSUPPORTED_RESPONSE
          @error_description = "Response type #{@params['response_type']} is not supported"
        end
        
        @client = Model::Client.find_by_client_id(@params['client_id'])
        unless @client
          @error = INVALID_CLIENT
          @error_description = "Unknown client ID #{@params['client_id']}"
        end
        
        if @client and @client.redirect_uri and @client.redirect_uri != @params['redirect_uri']
          @error = REDIRECT_MISMATCH
          @error_description = "Parameter redirect_uri does not match registered URI"
        end
      end
      
      def to_query_string(*ivars)
        ivars.map { |key|
          value = instance_variable_get("@#{key}")
          value = value.join(' ') if Array === value
          value ? "#{ key }=#{ URI.escape(value.to_s) }" : nil
        }.compact.join('&')
      end
    end
    
  end
end

