dir = File.expand_path(File.dirname(__FILE__))
$:.unshift(dir + '/../lib')
$:.unshift(dir)

require 'rubygems'

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

module RequestHelpers
  def get(query_params)
    qs  = params.map { |k,v| "#{ URI.escape k.to_s }=#{ URI.escape v.to_s }" }.join('&')
    uri = URI.parse('http://localhost:8000/authorize?' + qs)
    Net::HTTP.get_response(uri)
  end
  
  def allow_or_deny(query_params)
    Net::HTTP.post_form(URI.parse('http://localhost:8000/allow'), query_params)
  end
  
  def post_basic_auth(auth_params, query_params)
    url = "http://#{ auth_params['client_id'] }:#{ auth_params['client_secret'] }@localhost:8000/authorize"
    Net::HTTP.post_form(URI.parse(url), query_params)
  end
  
  def post(query_params)
    Net::HTTP.post_form(URI.parse('http://localhost:8000/authorize'), query_params)
  end
  
  def validate_json_response(response, status, body)
    response.code.to_i.should == status
    JSON.parse(response.body).should == body
    response['Content-Type'].should == 'application/json'
    response['Cache-Control'].should == 'no-store'
  end
  
  def mock_request(request_class, stubs = {})
    mock_request = mock(request_class)
    method_stubs = {
      :redirect?        => false,
      :response_body    => nil,
      :response_headers => {},
      :response_status  => 200
    }.merge(stubs)
    
    method_stubs.each do |method, value|
      mock_request.should_receive(method).and_return(value)
    end
    
    mock_request
  end
end

require 'thin'
Thin::Logging.silent = true

require 'factories'

RSpec.configure do |config|
  config.after do
    [ OAuth2::Model::Client,
      OAuth2::Model::Authorization,
      TestApp::User
      
    ].each { |k| k.delete_all }
  end
end

