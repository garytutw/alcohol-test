require 'rubygems'
require 'bundler/setup'
Bundler.require

namespace :dev do
  desc 'Start in development mode'
  task :start do
    system 'thin -e development start'
  end
end

namespace :live do
  desc 'Start production process on [port]'
  task :start, [:port] do |t, args|
    system "thin -C thin-production-config.yaml -o #{args.port} start" if args.port
    system 'thin -C thin-production-config.yaml start' unless args.port
  end

  desc 'Stop production process on [port]'
  task :stop, [:port] do |t, args|
    system "thin -C thin-production-config.yaml -o #{args.port} stop" if args.port
    system 'thin -C thin-production-config.yaml stop' unless args.port
  end

  desc 'Restart production process'
  task :restart do
    system 'thin -C thin-production-config.yaml restart'
  end

  desc 'Show production process status'
  task :status do
    puts 'Proto Recv-Q  Send-Q  Local Address Foreign Address State PID/Program name'
    system 'netstat -tnlp 2>/dev/null | grep thin'
  end
end


# Log file management
namespace :logs do
  desc 'Purge all logs'
  task :purge do
    system 'rm -f log/*.log'
  end

  desc 'View end of log files'
  task :tail do
    system 'tail log/*.log'
  end
end

# Database management
namespace :db do
  desc 'Auto-migrate the database (destroy data)'
  task :migrate do
    puts 'Bootstrapping database (destroy data)'
    require_relative 'bootstrap.rb'
    DataMapper.finalize
    DataMapper.auto_migrate!
  end

  desc 'Auto-upgrade the database (preserve data)'
  task :migrate do
    puts 'Upgrading database (preserve data)'
    require_relative 'bootstrap.rb'
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end
end
