require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
Bundler.require

def root_dir
  File.dirname(__FILE__)
end

# Helper libraries
Dir["#{root_dir}/helpers/*.rb"].each {|f| require_relative f}

# Models
Dir["#{root_dir}/../models/*.rb"].each {|f| require_relative f}

# Routes
Dir["#{root_dir}/routes/*.rb"].each {|f| require_relative f}

# Cron jobs
Dir["#{root_dir}/crons/*.rb"].each {|f| require_relative f}

class Application < Sinatra::Base

  puts ">> Running in #{settings.environment} environment"

  ## Sinatra Settings ##
  # http://www.sinatrarb.com/configuration.html
  enable :sessions
  set :root, "#{root_dir}"
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
    cfg = YAML.load_file('config/production.yaml')
    DataMapper.setup :default, cfg['DATABASE_URL']
  end

end



