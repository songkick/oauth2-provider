module OAuth2
  class Provider
    
    class Exchange
      attr_reader :client, :error, :error_description
      
      REQUIRED_PARAMS    = %w[client_id client_secret grant_type]
      VALID_GRANT_TYPES  = %w[authorization_code refresh_token]
      
      RESPONSE_HEADERS = {
        'Cache-Control' => 'no-store',
        'Content-Type'  => 'application/json'
      }
      
      def initialize(resource_owner, params)
        @params     = params
        @scope      = params[SCOPE]
        @grant_type = @params[GRANT_TYPE]
        validate!
      end
      
      def owner
        @authorization && @authorization.owner
      end
      
      def scopes
        @scope ? @scope.split(/\s+/).delete_if { |s| s.empty? } : []
      end
      
      def redirect?
        false
      end
      
      def response_body
        return jsonize(ERROR, ERROR_DESCRIPTION) unless valid?
        update_authorization
        
        response = {}
        %w[access_token refresh_token scope].each do |key|
          value = @authorization.__send__(key)
          response[key] = value if value
        end
        
        JSON.unparse(response)
      end
      
      def response_headers
        RESPONSE_HEADERS
      end
      
      def response_status
        valid? ? 200 : 400
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
        validate_required_params
        
        return if @error
        validate_client
        
        valid_grant_types = VALID_GRANT_TYPES + Provider.extension_types
        
        unless valid_grant_types.include?(@grant_type)
          @error = UNSUPPORTED_GRANT_TYPE
          @error_description = "The grant type #{@grant_type} is not recognized"
        end
        return if @error
        
        validation_type = VALID_GRANT_TYPES.include?(@grant_type) ? @grant_type : 'extension'
        __send__("validate_#{ validation_type }")
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
        @client = Model::Client.find_by_client_id(@params[CLIENT_ID])
        unless @client
          @error = INVALID_CLIENT
          @error_description = "Unknown client ID #{@params[CLIENT_ID]}"
        end
        
        if @client and not @client.valid_client_secret? @params[CLIENT_SECRET]
          @error = INVALID_CLIENT
          @error_description = 'Parameter client_secret does not match'
        end
      end
      
      def validate_scope
        if @authorization and not @authorization.in_scope?(scopes)
          @error = INVALID_SCOPE
          @error_description = 'The request scope was never granted by the user'
        end
      end
      
      def validate_authorization_code
        unless @params[CODE]
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter code"
        end
        
        if @client.redirect_uri and @client.redirect_uri != @params[REDIRECT_URI]
          @error = REDIRECT_MISMATCH
          @error_description = "Parameter redirect_uri does not match registered URI"
        end
        
        unless @params.has_key?(REDIRECT_URI)
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter redirect_uri"
        end
        
        return if @error
        
        @authorization = @client.authorizations.find_by_code(@params[CODE])
        validate_authorization
      end
      
      def validate_extension
        @authorization = Provider.handle_extension(@client, @grant_type, @params.dup)
        return validate_authorization if @authorization
        
        @error = UNAUTHORIZED_CLIENT
        @error_description = 'Client cannot use the given grant type'
      end
      
      def validate_refresh_token
        refresh_token_hash = OAuth2.hashify(@params[REFRESH_TOKEN])
        @authorization = @client.authorizations.find_by_refresh_token_hash(refresh_token_hash)
        validate_authorization
      end
      
      def validate_authorization
        unless @authorization
          @error = INVALID_GRANT
          @error_description = 'The access grant you supplied is invalid'
        end
        
        if @authorization and @authorization.expired?
          @error = INVALID_GRANT
          @error_description = 'The access grant you supplied is invalid'
        end
      end
    end
    
  end
end

