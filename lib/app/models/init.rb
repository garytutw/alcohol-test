require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
Bundler.require

# Models
require_relative 'users'
require_relative 'driver'
require_relative 'site'
require_relative 'site_report'
require_relative 'site_report_log'
require_relative 'alcohol_test'

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
