class User < ActiveRecord::Base
  include OAuth2::ResourceOwner
  has_many :notes
end

