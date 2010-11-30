class User < ActiveRecord::Base
  include OAuth2::Model::ResourceOwner
  has_many :notes
end

