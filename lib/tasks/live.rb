
namespace :live do
  desc 'Start production process on [port]'
  task :start, [:port] do |t, args|
    system "thin -C config/thin-production.yaml -o #{args.port} start" if args.port
    system 'thin -C config/thin-production.yaml start' unless args.port
  end

  desc 'Stop production process on [port]'
  task :stop, [:port] do |t, args|
    system "thin -C config/thin-production.yaml -o #{args.port} stop" if args.port
    system 'thin -C config/thin-production.yaml stop' unless args.port
  end

  desc 'Restart production process'
  task :restart do
    system 'thin -C config/thin-production.yaml restart'
  end

  desc 'Show production process status'
  task :status do
    puts 'Proto Recv-Q  Send-Q  Local Address Foreign Address State PID/Program name'
    system 'netstat -tnlp 2>/dev/null | grep thin'
  end
end

