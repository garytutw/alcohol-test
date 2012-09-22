require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
Bundler.require

# Models
Dir["#{File.dirname(__FILE__)}/models/*.rb"].each {|f| require_relative f}
DataMapper.finalize

class Application < Sinatra::Base

  puts ">> Running in #{settings.environment} environment"

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
