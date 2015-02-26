#Monkey patched Songkick as it didnt use the right request Header Autorization setup. Changed OAuth to Bearer. As Oauth in Authorization isnt of the latest standard
#and Bearer is.
module Songkick
  module OAuth2
    class Provider

      class AccessToken
        attr_reader :authorization, :error

        def initialize(resource_owner = nil, scopes = [], access_token = nil, error = nil)
          @resource_owner = resource_owner
          @scopes         = scopes
          @access_token   = access_token
          @error          = error && INVALID_REQUEST

          authorize!(access_token, error)
          validate!
        end

        def client
          valid? ? @authorization.client : nil
        end

        def owner
          valid? ? @authorization.owner : nil
        end

        def response_headers
          return {} if valid?
          error_message =  "Bearer realm='#{ Provider.realm }'"
          error_message << ", error='#{ @error }'" unless @error == ''
          {'WWW-Authenticate' => error_message}
        end

        def response_status
          case @error
            when INVALID_REQUEST, INVALID_TOKEN, EXPIRED_TOKEN then 401
            when INSUFFICIENT_SCOPE                            then 403
            when ''                                            then 401
            else 200
          end
        end

        def valid?
          @error.nil?
        end

        private

        def authorize!(access_token, error)
          return unless @authorization = Model.find_access_token(access_token)
          @authorization.update_attribute(:access_token, nil) if error
        end

        def validate!
          return @error = ''                 unless @access_token
          return @error = INVALID_TOKEN      unless @authorization
          return @error = EXPIRED_TOKEN      if @authorization.expired?
          return @error = INSUFFICIENT_SCOPE unless @authorization.in_scope?(@scopes)

          case @resource_owner
            when :implicit
              # no error
            when nil
              @error = INVALID_TOKEN
            else
              @error = INSUFFICIENT_SCOPE if @authorization.owner != @resource_owner
          end
        end
      end

    end
  end
end
