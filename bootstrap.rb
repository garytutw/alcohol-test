require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
Bundler.require

# Helper libraries
Dir['helpers/*.rb'].each {|f| require_relative f}

class Application < Sinatra::Base

  puts ">> Running in #{settings.environment} environment"

  ## Sinatra Settings ##
  # http://www.sinatrarb.com/configuration.html
  enable :sessions
  helpers Helpers

  configure :development do
    Bundler.require :development
    use Rack::CommonLogger
    DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup :default, "sqlite:database.db"
  end

  configure :test do
    Bundler.require :test
    DataMapper.setup :default, "sqlite::memory:"
  end

  configure :production do
    Bundler.require :production
    DataMapper.setup :default, ENV['DATABASE_URL']
  end

end


# Models
Dir['models/*.rb'].each {|f| require_relative f}

# Routes
Dir['routes/*.rb'].each {|f| require_relative f}

# Cron jobs
Dir['crons/*.rb'].each {|f| require_relative f}


