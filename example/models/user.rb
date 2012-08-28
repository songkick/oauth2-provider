class User < ActiveRecord::Base
  include Songkick::OAuth2::Model::ResourceOwner
  include Songkick::OAuth2::Model::ClientOwner
  has_many :notes
end

