
namespace :db do
  desc 'Auto-migrate the database (destroy data)'
  task :migrate do
    puts 'Bootstrapping database (destroy data)'
    require_relative '../app/bootstrap.rb'
    DataMapper.auto_migrate!
  end

  desc 'Auto-upgrade the database (preserve data)'
  task :upgrade do
    puts 'Upgrading database (preserve data)'
    require_relative '../app/bootstrap.rb'
    DataMapper.auto_upgrade!
  end
  
  desc 'Populating data for testing'
  task :populate do
    puts 'Populating test data into database'
    require_relative '../app/bootstrap.rb'
    File.open('test/data.csv').each_line do |l|
      CSV.parse(l.encode('utf-8', 'big5')) do |r|
        driver = Driver.first_or_create(:serial => Integer(r[0]))
        site = Site.first_or_create({ :name => r[13]}, { :seq => 1})
        at = AlcoholTest.new(:value => Float(r[1]), :time => Time.now,
                             :image => r[4], :driver => driver, :site => site)
        at.save
      end
    end
  end
end

