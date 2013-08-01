dir = File.expand_path('..', __FILE__)
require dir + '/environment'

require 'sinatra'
require 'json'

set :static, true
set :root, dir
enable :sessions

PERMISSIONS = {
  'read_notes' => 'Read all your notes'
}

ERROR_RESPONSE = JSON.unparse('error' => 'No soup for you!')

get('/') { erb(:home) }


get '/users/new' do
  @user = User.new
  erb :new_user
end

post '/users/create' do
  @user = User.create(params)
  if @user.save
    erb :create_user
  else
    erb :new_user
  end
end

#================================================================
# Register applications

get '/oauth/apps/new' do
  @client = Songkick::OAuth2::Model::Client.new
  erb :new_client
end

post '/oauth/apps' do
  @client = Songkick::OAuth2::Model::Client.new(params)
  if @client.save
    session[:client_secret] = @client.client_secret
    redirect("/oauth/apps/#{@client.id}")
  else
    erb :new_client
  end
end

get '/oauth/apps/:id' do
  @client = Songkick::OAuth2::Model::Client.find_by_id(params[:id])
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
    @oauth2 = Songkick::OAuth2::Provider.parse(@user, env)

    if @oauth2.redirect?
      redirect @oauth2.redirect_uri, @oauth2.response_status
    end

    headers @oauth2.response_headers
    status  @oauth2.response_status

    if body = @oauth2.response_body
      body
    elsif @oauth2.valid?
      erb :login
    else
      erb :error
    end
  end
end

post '/login' do
  @user = User.find_by_username(params[:username])
  @oauth2 = Songkick::OAuth2::Provider.parse(@user, env)
  session[:user_id] = @user.id
  erb(@user ? :authorize : :login)
end

post '/oauth/allow' do
  @user = User.find_by_id(session[:user_id])
  @auth = Songkick::OAuth2::Provider::Authorization.new(@user, params)
  if params['allow'] == '1'
    @auth.grant_access!
  else
    @auth.deny_access!
  end
  redirect @auth.redirect_uri, @auth.response_status
end

#================================================================
# Domain API

get '/me' do
  authorization = Songkick::OAuth2::Provider.access_token(:implicit, [], env)
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
    token = Songkick::OAuth2::Provider.access_token(user, [scope.to_s], env)

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

