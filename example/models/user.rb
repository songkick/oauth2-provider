class User < ActiveRecord::Base
  include OAuth2::Model::AuthorizationOwner
  include OAuth2::Model::ClientOwner
  has_many :notes
end

