module OAuth2
  class Provider
    
    class Authorization
      attr_reader :error, :error_description
      
      REQUIRED_PARAMS = [:response_type, :client_id, :redirect_uri]
      INVALID_REQUEST = 'invalid_request'
      
      def initialize(params)
        @params = params
        REQUIRED_PARAMS.each do |param|
          next if @params.has_key?(param)
          @error = INVALID_REQUEST
          @error_description = "Missing required parameter #{param}"
        end
      end
    end
    
  end
end

