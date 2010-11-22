module OAuth2
  class Provider
    
    class Token
      AUTHORIZATION_CODE = 'authorization_code'
      
      RESPONSE_HEADERS = {
        'Cache-Control' => 'no-store',
        'Content-Type'  => 'application/json'
      }
      
      def initialize(params)
        @params        = params
        @client_id     = params['client_id']
        @client_secret = params['client_secret']
        @grant_type    = params['grant_type']
        @code          = params['code']
        @redirect_uri  = params['redirect_uri']
        validate!
      end
      
      def redirect?
        false
      end
      
      def response_body
        return JSON.unparse('error' => @error) unless valid?
        
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
        case @grant_type
          when AUTHORIZATION_CODE
            unless @code
              @error = INVALID_REQUEST
              "Missing required parameter code"
            end
        end
      end
    end
    
  end
end

