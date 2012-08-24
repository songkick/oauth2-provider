require 'rubygems'
require 'bundler/setup'

require 'active_record'
require File.expand_path('../../lib/oauth2/provider', __FILE__)

dbfile = File.expand_path('../test.sqlite3', __FILE__)
File.unlink(dbfile) if File.file?(dbfile)
ActiveRecord::Base.establish_connection(:adapter  => 'sqlite3', :database => dbfile)

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::INFO

OAuth2::Model::Schema.up

ActiveRecord::Schema.define do |version|
  create_table :users, :force => true do |t|
    t.string :name
  end
end

require File.expand_path('../test_app/helper', __FILE__)
require File.expand_path('../test_app/provider/application', __FILE__)

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

