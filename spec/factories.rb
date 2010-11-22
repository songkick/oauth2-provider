require 'factory_girl'

Factory.define :client, :class => OAuth2::Model::Client do |c|
  c.client_id     { OAuth2.random_string }
  c.client_secret { OAuth2.random_string }
  c.name          'Test client'
  c.redirect_uri  'https://client.example.com/cb'
end

Factory.define :authorization, :class => OAuth2::Model::Authorization do |ac|
  ac.client     Factory(:client)
  ac.code       'i1WsRn1uB1'
  ac.expires_at 1.hour.from_now
end

