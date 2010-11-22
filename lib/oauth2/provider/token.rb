module OAuth2
  class Provider
    
    class Token
      attr_reader :error, :error_description
      
      REQUIRED_PARAMS    = %w[client_id client_secret grant_type]
      AUTHORIZATION_CODE = 'authorization_code'
      VALID_GRANT_TYPES  = [AUTHORIZATION_CODE]
      
      RESPONSE_HEADERS = {
        'Cache-Control' => 'no-store',
        'Content-Type'  => 'application/json'
      }
      
      def initialize(params)
        @params     = params
        @grant_type = @params['grant_type']
        validate!
      end
      
      def redirect?
        false
      end
      
      def response_body
        return jsonize(:error, :error_description) unless valid?
        
        JSON.unparse(
          'access_token'  => 'SlAV32hkKG',
          'expires_in'    => 3600,
          'refresh_token' => '8xLOxBtZp8')
      end
      
      def response_headers
        RESPONSE_HEADERS
      end
      
      def response_status
        valid? ? 200 : 400
      end
      
      def valid?
        @error.nil?
      end
      
    private
      
      def validate!
        validate_required_params
        
        return if @error
        validate_client
        
        unless VALID_GRANT_TYPES.include?(@grant_type)
          @error = UNSUPPORTED_GRANT_TYPE
          @error_description = "The grant type #{@grant_type} is not recognized"
        end
        return if @error
        
        __send__("validate_#{@grant_type}")
      end
      
      def validate_required_params
        REQUIRED_PARAMS.each do |param|
          next if @params.has_key?(param)
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter #{param}"
        end
      end
      
      def validate_client
        @client = Model::Client.find_by_client_id(@params['client_id'])
        unless @client
          @error = INVALID_CLIENT
          @error_description = "Unknown client ID #{@params['client_id']}"
        end
        
        if @client and @client.client_secret != @params['client_secret']
          @error = INVALID_CLIENT
          @error_description = 'Parameter client_secret does not match'
        end
      end
      
      def validate_authorization_code
        unless @params['code']
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter code"
        end
        
        if @client.redirect_uri and @client.redirect_uri != @params['redirect_uri']
          @error = REDIRECT_MISMATCH
          @error_description = "Parameter redirect_uri does not match registered URI"
        end
        
        unless @params.has_key?('redirect_uri')
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter redirect_uri"
        end
        
        return if @error
        
        @access_code = @client.access_codes.find_by_code(@params['code'])
        unless @access_code
          @error = INVALID_GRANT
          @error_description = 'The access grant you supplied is invalid'
        end
        
        if @access_code and @access_code.expired?
          @error = INVALID_GRANT
          @error_description = 'The access grant you supplied is invalid'
        end
      end
      
      def jsonize(*ivars)
        hash = {}
        ivars.each { |key| hash[key] = instance_variable_get("@#{key}") }
        JSON.unparse(hash)
      end
    end
    
  end
end

