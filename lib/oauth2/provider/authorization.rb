module OAuth2
  class Provider
    
    class Authorization
      attr_reader :params, :client,
                  :code, :access_token,
                  :refresh_token, :expires_in,
                  :error, :error_description
      
      REQUIRED_PARAMS = %w[response_type client_id redirect_uri]
      VALID_RESPONSES = %w[code token code_and_token]
      
      def initialize(params)
        @params = params
        @scope  = params['scope']
        @state  = params['state']
        validate!
      end
      
      def scope
        @scope ? @scope.split(/\s+/).delete_if { |s| s.empty? } : []
      end
      
      def grant_access(resource_owner)
        case @params['response_type']
          when 'code'
            @code = OAuth2.random_string
          when 'token'
            @access_token  = OAuth2.random_string
            @refresh_token = OAuth2.random_string
          when 'code_and_token'
            @code = OAuth2.random_string
            @access_token  = OAuth2.random_string
            @refresh_token = OAuth2.random_string
        end
        
        @expires_in  = EXPIRY_TIME
        expiry       = Time.now + EXPIRY_TIME
        
        Model::Authorization.create(
          :oauth2_resource_owner => resource_owner,
          :client        => @client,
          :code          => @code,
          :access_token  => @access_token,
          :refresh_token => @refresh_token,
          :scope         => @scope,
          :expires_at    => expiry)
      end
      
      def deny_access
        @code = @access_token = @refresh_token = @expires_in = nil
        @error = ACCESS_DENIED
        @error_description = "The user denied you access"
      end
      
      def redirect?
        not valid?
      end
      
      def redirect_uri
        if not valid?
          query = to_query_string(:error, :error_description, :state)
          "#{ @params['redirect_uri'] }?#{ query }"
        
        elsif @params['response_type'] == 'code_and_token'
          query    = to_query_string(:code, :state)
          fragment = to_query_string(:access_token, :expires_in, :scope)
          "#{ @params['redirect_uri'] }#{ query.empty? ? '' : '?' + query }##{ fragment }"
        
        elsif @params['response_type'] == 'token'
          fragment = to_query_string(:access_token, :expires_in, :scope, :state)
          "#{ @params['redirect_uri'] }##{ fragment }"
        
        else
          query = to_query_string(:code, :expires_in, :scope, :state)
          "#{ @params['redirect_uri'] }?#{ query }"
        end
      end
      
      def response_body
      end
      
      def response_headers
        {}
      end
      
      def response_status
        valid? ? 200 : 302
      end
      
      def valid?
        @error.nil?
      end
      
    private
      
      def validate!
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

