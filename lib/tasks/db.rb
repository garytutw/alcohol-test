
namespace :db do
  require_relative '../app/models/init'
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
    i = 1
    Site.all.each do |s|
      s.update_report(Date.today - 1)
      s.update_report(Date.today - 2)
      s.seq = i
      i += 1
      s.save
    end
    # admin user
    User.create(:id => 'admin', :name => 'admin',
                :password => 'admin', :password_confirmation => 'admin',
                :permission_level => -1).save
    User.create(:id => 'hq', :name => 'hq',
                :password => '1234', :password_confirmation => '1234',
                :permission_level => 0).save
    User.create(:id => 'site1', :name => 'site1',
                :password => '1234', :password_confirmation => '1234',
                :permission_level => 1, :site_id => 1).save
    User.create(:id => 'site2', :name => 'site2',
                :password => '1234', :password_confirmation => '1234',
                :permission_level => 1, :site_id => 2).save
    User.create(:id => 'op1', :name => 'op1',
                :password => '1234', :password_confirmation => '1234',
                :permission_level => 2, :site_id => 1).save
    User.create(:id => 'op2', :name => 'op2',
                :password => '1234', :password_confirmation => '1234',
                :permission_level => 2, :site_id => 2).save
  end
end

