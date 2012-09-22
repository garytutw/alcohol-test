require 'rubygems'
require 'sinatra'
require 'haml'
require "dm-core"
require "dm-migrations"
require 'sinatra/flash'
require '../models/users.rb'
require '../helpers/authorization.rb'

#DataMapper.setup(:default, "mysql://root:cow3xiao@localhost/test")
#DataMapper.auto_upgrade!
use Rack::Session::Cookie, :secret => 'superdupersecret'
enable :session
set :root, Pathname(__FILE__).dirname.expand_path + "../"

get "/" do
  #all_users
  haml :index
end

get "/signup" do
  haml :signup
end

post "/signup" do
  user = User.create(params[:user])
  user.password_salt = BCrypt::Engine.generate_salt
  user.password_hash = BCrypt::Engine.hash_secret(params[:user][:password], user.password_salt)
  if user.save
    flash[:info] = "Thank you for registering #{user.name}" 
    session[:user] = user.token
    redirect "/" 
  else
    session[:errors] = user.errors.full_messages
    puts "error: ${user.errors.full_messages}"
    redirect "/signup?" + hash_to_query_string(params[:user])
  end
end

get "/login" do
  if current_user
    redirect_last
  else
    haml :login
  end
end

post "/login" do
  if user = User.first(:id => params[:id])
    if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
    session[:user] = user.token 
    response.set_cookie "user", {:value => user.token, :expires => (Time.now + 52*7*24*60*60)} if params[:remember_me]
    redirect_last
    else
      flash[:error] = "ID/Password combination does not match"
      redirect "/login?id=#{params[:id]}"
    end
  else
    flash[:error] = "That serial ID is not recognised"
    redirect "/login?id=#{params[:id]}"
  end
end

get "/logout" do
  if current_user
    @current_user.generate_token
    response.delete_cookie "user"
    session[:user] = nil
    flash[:info] = "Successfully logged out"
    redirect "/"
  end
  redirect "/login"
end
#=============== testing only ===================
get "/secret" do
  login_required
  "This is a secret secret"
end

get "/supersecret" do
   if current_user
    admin_required
    "Well done on being super special. You're a star!"
  else
    haml :login
  end
  
end

get "/personal/:id" do
  is_owner? params[:id]
  "<pre>id: #{current_user.id}\nname: #{current_user.name}\nadmin? #{current_user.admin}</pre>"
end
