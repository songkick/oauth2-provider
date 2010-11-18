module OAuth2
  class Provider
    
    class Authorization
      attr_reader :client, :error, :error_description
      
      REQUIRED_PARAMS      = %w[response_type client_id redirect_uri]
      VALID_RESPONSES      = %w[code token code_and_token]
      INVALID_REQUEST      = 'invalid_request'
      UNSUPPORTED_RESPONSE = 'unsupported_response_type'
      REDIRECT_MISMATCH    = 'redirect_uri_mismatch'
      INVALID_CLIENT       = 'invalid_client'
      
      def initialize(params)
        @params = params
        validate!
      end
      
      def valid?
        @error.nil?
      end
      
      def redirect_url
        qs = %w[error error_description].map { |key|
          value = CGI.escape(instance_variable_get("@#{key}"))
          "#{ key }=#{ value }"
        }.join('&')
        
        if @params['state']
          qs << "&state=#{ CGI.escape(@params['state']) }"
        end
        
        "#{ @params['redirect_uri'] }?#{ qs }"
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
        
        if @client and @client.redirect_uri != @params['redirect_uri']
          @error = REDIRECT_MISMATCH
          @error_description = "Parameter redirect_uri does not match registered URI"
        end
      end
    end
    
  end
end

