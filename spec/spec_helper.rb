dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'rubygems'
require 'oauth2/provider'
require 'test_app/helper'
require 'test_app/provider/application'

require 'thin'
Thin::Logging.silent = true

require 'active_record'
ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => 'test.db')
ActiveRecord::Schema.define(&OAuth2::Model::SCHEMA)

RSpec.configure do |config|
  config.after do
    [OAuth2::Model::Client, OAuth2::Model::AccessCode].each { |k| k.destroy_all }
  end
end

