require 'rubygems'
require 'bundler/setup'

require 'active_record'
require 'protected_attributes' if defined?(ActiveRecord::VERSION) && ActiveRecord::VERSION::MAJOR > 3

require 'songkick/oauth2/provider'

case ENV['DB']
  when 'mysql'
    ActiveRecord::Base.establish_connection(
        :adapter  => 'mysql',
        :host     => '127.0.0.1',
        :username => 'root',
        :database => 'oauth2_test')
  when 'postgres'
    ActiveRecord::Base.establish_connection(
        :adapter  => 'postgresql',
        :host     => '127.0.0.1',
        :username => 'postgres',
        :database => 'oauth2_test')
  else
    dbfile = File.expand_path('../test.sqlite3', __FILE__)
    File.unlink(dbfile) if File.file?(dbfile)

    ActiveRecord::Base.establish_connection(
        :adapter  => 'sqlite3',
        :database => dbfile)
end

require 'logger'
ActiveRecord::Base.logger = Logger.new(STDERR)
ActiveRecord::Base.logger.level = Logger::INFO

Songkick::OAuth2::Model::Schema.up

ActiveRecord::Schema.define do |version|
  create_table :users, :force => true do |t|
    t.string :name
  end
end

require 'test_app/provider/application'
require 'request_helpers'
require 'factories'

require 'thin'
Thin::Logging.silent = true
$VERBOSE = nil

RSpec.configure do |config|
  # to run only specific specs, add :focus to the spec
  #   describe "foo", :focus do
  # OR
  #   it "should foo", :focus do
  config.treat_symbols_as_metadata_keys_with_true_values = true # default in rspec 3
  config.filter_run :focus => true
  config.run_all_when_everything_filtered = true

  config.before do
    Songkick::OAuth2::Provider.enforce_ssl = false
    time = Time.now
    Time.stub(:now).and_return time
  end

  config.after do
    [ Songkick::OAuth2::Model::Client,
      Songkick::OAuth2::Model::Authorization,
      TestApp::User

    ].each { |k| k.delete_all }
  end
end

def create_authorization(params)
  Songkick::OAuth2::Model::Authorization.__send__(:create) do |authorization|
    params.each do |key, value|
      authorization.__send__ "#{key}=", value
    end
  end
end

