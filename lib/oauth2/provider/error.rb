module OAuth2
  class Provider
    
    class Error
      def redirect?
        false
      end
      
      def response_body
        JSON.unparse(:error => INVALID_REQUEST, :error_description => 'Bad request')
      end
      
      def response_headers
        Token::RESPONSE_HEADERS
      end
      
      def response_status
        400
      end
    end
    
  end
end

