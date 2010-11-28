dir = File.expand_path(File.dirname(__FILE__))
require dir + '/environment'

require 'sinatra'
require 'json'

set :static, true
set :public, dir + '/public'
set :views,  dir + '/views'
enable :sessions

PERMISSIONS = {
  'read_notes' => 'Read all your notes'
}

ERROR_RESPONSE = JSON.unparse('error' => 'No soup for you!')

get('/') { erb(:home) }


#================================================================
# Register applications

get '/oauth/apps/new' do
  @client = OAuth2::Model::Client.new
  erb :new_client
end

post '/oauth/apps' do
  @client = OAuth2::Model::Client.new(params)
  if @client.save
    session[:client_secret] = @client.client_secret
    redirect("/oauth/apps/#{@client.id}")
  else
    erb :new_client
  end
end

get '/oauth/apps/:id' do
  @client = OAuth2::Model::Client.find_by_id(params[:id])
  @client_secret = session[:client_secret]
  erb :show_client
end


#================================================================
# OAuth 2.0 flow

# Initial request exmample:
# /oauth/authorize?response_type=token&client_id=7uljxxdgsksmecn5cycvug46v&redirect_uri=http%3A%2F%2Fexample.com%2Fcb&scope=read_notes
[:get, :post].each do |method|
  __send__ method, '/oauth/authorize' do
    @user = User.find_by_id(session[:user_id])
    @oauth2 = OAuth2::Provider.parse(@user, request)
    redirect @oauth2.redirect_uri if @oauth2.redirect?
        
    headers @oauth2.response_headers
    status  @oauth2.response_status
    
    @oauth2.response_body || erb(:login)
  end
end

post '/login' do
  @user = User.find_by_username(params[:username])
  @oauth2 = OAuth2::Provider.parse(@user, request)
  session[:user_id] = @user.id
  erb(@user ? :authorize : :login)
end

post '/oauth/allow' do
  @user = User.find_by_id(session[:user_id])
  @auth = OAuth2::Provider::Authorization.new(@user, params)
  if params['allow'] == '1'
    @auth.grant_access!
  else
    @auth.deny_access!
  end
  redirect @auth.redirect_uri
end


#================================================================
# Domain API

get '/me' do
  authorization = OAuth2::Provider.access_token(nil, [], request)
  headers authorization.response_headers
  status  authorization.response_status
  
  if authorization.valid?
    user = authorization.owner
    JSON.unparse('username' => user.username)
  else
    ERROR_RESPONSE
  end
end

get '/users/:username/notes' do
  verify_access :read_notes do |user|
    notes = user.notes.map do |n|
      {:note_id => n.id, :url => "#{host}/users/#{user.username}/notes/#{n.id}"}
    end
    JSON.unparse(:notes => notes)
  end
end

get '/users/:username/notes/:note_id' do
  verify_access :read_notes do |user|
    note = user.notes.find_by_id(params[:note_id])
    note ? note.to_json : JSON.unparse(:error => 'No such note')
  end
end



helpers do
  #================================================================
  # Check for OAuth access before rendering a resource
  def verify_access(scope)
    user  = User.find_by_username(params[:username])
    token = OAuth2::Provider.access_token(user, [scope.to_s], request)
    
    headers token.response_headers
    status  token.response_status
    
    return ERROR_RESPONSE unless token.valid?
    
    yield user
  end
  
  #================================================================
  # Return the full app domain
  def host
    request.scheme + '://' + request.host_with_port
  end
end

