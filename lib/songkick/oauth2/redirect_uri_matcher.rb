module Songkick
  module OAuth2
    class RedirectURIMatcher

      class << self

        def match?(client_uri, param_uri)
          Globber.new(client_uri) =~ param_uri
        end

      end

    end
  end
end
