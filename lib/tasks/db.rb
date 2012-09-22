
namespace :db do
  require_relative '../app/models.rb'
  desc 'Auto-migrate the database (destroy data)'
  task :migrate do
    puts 'Bootstrapping database (destroy data)'
    DataMapper.auto_migrate!
  end

  desc 'Auto-upgrade the database (preserve data)'
  task :upgrade do
    puts 'Upgrading database (preserve data)'
    DataMapper.auto_upgrade!
  end
  
  desc 'Populating data for testing'
  task :populate do
    puts 'Populating test data into database'
    def insert_csv(file, delta=0)
      File.open(file).each_line do |l|
        CSV.parse(l.encode('utf-8', 'big5')) do |r|
          driver = Driver.first_or_create(:serial => Integer(r[0]))
          site = Site.first_or_create({ :name => r[13]}, { :seq => 1})
          at = AlcoholTest.new(:value => Float(r[1]), :time => Time.now+delta,
                               :image => r[4], :driver => driver, :site => site)
          at.save
        end
      end
    end
    insert_csv('test/data1.csv', -24*60*60)
    insert_csv('test/data2.csv', -24*60*60*2)    
    Site.all.each do |s|
      s.update_report(Date.today - 1)
      s.update_report(Date.today - 2)
    end
  end
end

