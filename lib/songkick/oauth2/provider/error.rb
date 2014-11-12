module Songkick
  module OAuth2
    class Provider

      class Error
        def initialize(message = nil)
          @message = message
        end

        def error
          INVALID_REQUEST
        end

        def error_description
          'Bad request' + (@message ? ": #{@message}" : '')
        end
      end

      class AlreadyExistsException < Exception
        def initialize(message = nil)
          @message = message
        end

        def error
          INVALID_REQUEST
        end

        def error_description
          'Bad request' + (@message ? ": #{@message}" : '')
        end
      end

    end
  end
end

