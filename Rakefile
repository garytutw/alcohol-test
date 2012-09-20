require 'rubygems'
require 'bundler/setup'
Bundler.require

Dir['./lib/tasks/*.rb'].each {|f| require_relative f}

require_relative './lib/app/bootstrap.rb'
task :test do
  File.open('test/data.csv').each_line do |l|
    CSV.parse(l.encode('utf-8', 'big5')) do |r|
      #driver = Driver.first_or_create({ :id => r[0]}, { :name => ''})
      #site = Site.first_or_create({ :name => r[13]}, { :seq => 1})
      driver = Driver.new(:id => Integer(r[0]), :name => '').save
      site = Site.new(:name => r[13], :seq => 1).save 
      at = AlcoholTest.new(:value => Float(r[1]), :time => Time.now, :image => r[4], :driver => driver, :site => site )
      at.save
    end
  end
end
