require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
Bundler.require
require_relative './models.rb'

def root_dir
  File.dirname(__FILE__)
end

# Helper libraries
Dir["#{root_dir}/helpers/*.rb"].each {|f| require_relative f}

# Routes
Dir["#{root_dir}/routes/*.rb"].each {|f| require_relative f}

# Cron jobs
Dir["#{root_dir}/crons/*.rb"].each {|f| require_relative f}

class Application < Sinatra::Base

  ## Sinatra Settings ##
  # http://www.sinatrarb.com/configuration.html
  enable :sessions
  set :root, "#{root_dir}"
  helpers Helpers

end



