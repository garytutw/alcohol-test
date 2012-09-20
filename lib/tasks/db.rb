
namespace :db do
  desc 'Auto-migrate the database (destroy data)'
  task :migrate do
    puts 'Bootstrapping database (destroy data)'
    require_relative '../app/bootstrap.rb'
    DataMapper.finalize
    DataMapper.auto_migrate!
  end

  desc 'Auto-upgrade the database (preserve data)'
  task :upgrade do
    puts 'Upgrading database (preserve data)'
    require_relative '../app/bootstrap.rb'
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end
end

