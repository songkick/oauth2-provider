module OAuth2
  class Provider
    
    class Authorization
      attr_reader :params, :client, :code, :access_token, :expires_in, :error, :error_description
      
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
      
      def grant_access!
        @code        = OAuth2.random_string
        @expires_in  = EXPIRY_TIME
        expiry       = Time.now + EXPIRY_TIME
        
        Model::AccessCode.create(:client => @client, :code => @code, :expires_at => expiry)
      end
      
      def deny_access!
        @error = ACCESS_DENIED
        @error_description = "The user denied you access"
      end
      
      def redirect?
        not valid?
      end
      
      def redirect_uri
        qs = valid? ?
             to_query_string(:code, :access_token, :expires_in, :scope, :state) :
             to_query_string(:error, :error_description, :state)
        
        "#{ @params['redirect_uri'] }?#{ qs }"
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

