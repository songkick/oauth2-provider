module OAuth2
  class Provider
    
    class Token
      attr_reader :error, :error_description
      
      REQUIRED_PARAMS    = %w[client_id client_secret grant_type]
      VALID_GRANT_TYPES  = %w[authorization_code refresh_token]
      
      RESPONSE_HEADERS = {
        'Cache-Control' => 'no-store',
        'Content-Type'  => 'application/json'
      }
      
      def initialize(params)
        @params     = params
        @scope      = params['scope']
        @grant_type = @params['grant_type']
        validate!
      end
      
      def scope
        @scope ? @scope.split(/\s+/).delete_if { |s| s.empty? } : []
      end
      
      def redirect?
        false
      end
      
      def response_body
        return jsonize(:error, :error_description) unless valid?
        update_authorization
        
        JSON.unparse(
          'access_token'  => @authorization.access_token,
          'expires_in'    => 3600,
          'refresh_token' => @authorization.refresh_token)
      end
      
      def response_headers
        RESPONSE_HEADERS
      end
      
      def response_status
        valid? ? 200 : 400
      end
      
      def update_authorization
        return if not valid? or @already_updated
        
        @authorization.update_attributes(
          :code          => nil,
          :access_token  => OAuth2.random_string,
          :refresh_token => OAuth2.random_string,
          :expires_at    => Time.now + EXPIRY_TIME)
        
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
        validate_required_params
        
        return if @error
        validate_client
        
        unless VALID_GRANT_TYPES.include?(@grant_type)
          @error = UNSUPPORTED_GRANT_TYPE
          @error_description = "The grant type #{@grant_type} is not recognized"
        end
        return if @error
        
        __send__("validate_#{@grant_type}")
        validate_scope
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
      
      def validate_scope
        if @authorization and not @authorization.in_scope?(scope)
          @error = INVALID_SCOPE
          @error_description = 'The request scope was never granted by the user'
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
        
        @authorization = @client.authorizations.find_by_code(@params['code'])
        validate_authorization
        
        if @authorization and @authorization.expired?
          @error = INVALID_GRANT
          @error_description = 'The access grant you supplied is invalid'
        end
      end
      
      def validate_refresh_token
        @authorization = @client.authorizations.find_by_refresh_token(@params['refresh_token'])
        validate_authorization
      end
      
      def validate_authorization
        unless @authorization
          @error = INVALID_GRANT
          @error_description = 'The access grant you supplied is invalid'
        end
      end
    end
    
  end
end

