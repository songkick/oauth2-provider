module OAuth2
  class Provider
    
    class Exchange
      attr_reader :client, :error, :error_description
      
      REQUIRED_PARAMS    = %w[client_id client_secret grant_type]
      VALID_GRANT_TYPES  = %w[authorization_code assertion refresh_token]
      
      RESPONSE_HEADERS = {
        'Cache-Control' => 'no-store',
        'Content-Type'  => 'application/json'
      }
      
      def initialize(resource_owner, params)
        @params     = params
        @scope      = params['scope']
        @grant_type = @params['grant_type']
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
        return jsonize(:error, :error_description) unless valid?
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
        
        if @client and not @client.valid_client_secret? @params['client_secret']
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
      end
      
      def validate_assertion
        %w[assertion_type assertion].each do |param|
          next if @params.has_key?(param)
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter #{param}"
        end
        
        if @params['assertion_type']
          uri = URI.parse(@params['assertion_type']) rescue nil
          unless uri and uri.absolute?
            @error = INVALID_REQUEST
            @error_description = 'Parameter assertion_type must be an absolute URI'
          end
        end
        
        return if @error
        
        assertion = Assertion.new(@params)
        @authorization = Provider.handle_assertion(@client, assertion)
        return validate_authorization if @authorization
        
        @error = UNAUTHORIZED_CLIENT
        @error_description = 'Client cannot use the given assertion type'
      end
      
      def validate_refresh_token
        refresh_token_hash = OAuth2.hashify(@params['refresh_token'])
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
    
    class Assertion
      attr_reader :type, :value
      def initialize(params)
        @type  = params['assertion_type']
        @value = params['assertion']
      end
    end
    
  end
end

