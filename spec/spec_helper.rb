dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'oauth2/provider'

ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => 'test.sqlite3')

OAuth2::Model::Schema.up

ActiveRecord::Schema.define do |version|
  create_table :users, :force => true do |t|
    t.string :name
  end
end

require 'test_app/helper'
require 'test_app/provider/application'

require 'request_helpers'

require 'thin'
Thin::Logging.silent = true

require 'factories'

RSpec.configure do |config|
  config.before do
    OAuth2::Provider.enforce_ssl = false
  end
  
  config.after do
    [ OAuth2::Model::Client,
      OAuth2::Model::Authorization,
      TestApp::User
      
    ].each { |k| k.delete_all }
  end
end

