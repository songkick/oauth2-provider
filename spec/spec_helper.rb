dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'oauth2/provider'

ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => 'test.sqlite3')

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::INFO

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
  # to run only specific specs, add :focus to the spec
  #   describe "foo", :focus do
  # OR
  #   it "should foo", :focus do
  config.treat_symbols_as_metadata_keys_with_true_values = true # default in rspec 3
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before do
    OAuth2::Provider.enforce_ssl = false
    time = Time.now
    Time.stub(:now).and_return time
  end
  
  config.after do
    [ OAuth2::Model::Client,
      OAuth2::Model::Authorization,
      TestApp::User
      
    ].each { |k| k.delete_all }
  end
end

def create_authorization(params)
  OAuth2::Model::Authorization.create do |authorization|
    params.each do |key, value|
      authorization.__send__ "#{key}=", value
    end
  end
end

