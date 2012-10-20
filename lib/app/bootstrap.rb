require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
Bundler.require
require_relative './models/init.rb'

def root_dir
  File.dirname(__FILE__)
end

# Helper libraries
Dir["#{root_dir}/helpers/*.rb"].each {|f| require_relative f}

class Application < Sinatra::Base

  ## Sinatra Settings ##
  # http://www.sinatrarb.com/configuration.html
  enable :sessions
  set :root, "#{root_dir}"
  use Rack::Session::Cookie, :secret => 'superdupersecret'
  helpers Helpers
  register Sinatra::Flash
	
	# define ACL routing condition
	set(:auth) do |*roles|   # <- notice the splat here
	  condition do
	   	unless logged_in? && roles.any? {|role| current_user.in_role? role }
	   		session[:redirect_to] ||= @env["REQUEST_URI"].to_s
	   		if !logged_in?
	     		redirect "/login", 303
	     	else
	     		flash[:warning] = "You are not authorize to access this page!"
	     	  redirect "/", 303
	     	end
	   	end
	  end
	end

end

# Routes
Dir["#{root_dir}/routes/*.rb"].each {|f| require_relative f}

