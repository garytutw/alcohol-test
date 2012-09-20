
namespace :log do
  desc 'Purge all logs'
  task :purge do
    system 'rm -f log/*.log'
  end

  desc 'View end of log files'
  task :tail do
    system 'tail log/*.log'
  end
end

