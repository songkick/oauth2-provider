require 'factory_girl'

Factory.define :client, :class => OAuth2::Model::Client do |c|
  c.client_id    's6BhdRkqt3'
  c.name         'Test client'
  c.redirect_uri 'https://client.example.com/cb'
end

