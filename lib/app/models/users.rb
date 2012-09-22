require "data_mapper"
require "bcrypt"
require "securerandom"

DataMapper::Logger.new($stdout, :debug)
#DataMapper.setup(:default, ENV['DATABASE_URL'] || "sqlite3://#{Dir.pwd}/db/auth.sqlite")
DataMapper.setup(:default, "mysql://root:cow3xiao@localhost/test")

class User 
  include DataMapper::Resource
  
  attr_accessor :password, :password_confirmation
  property :id, String, :key => true
  property :name, String, :required => true, :length => 10
  property :password_hash,  Text  
  property :password_salt,  Text
  property :created_at, DateTime
  property :token, String
  property :permission_level, Integer, :default => 1
  
  
  validates_presence_of         :password
  validates_presence_of         :password_confirmation
  validates_confirmation_of     :password
  #validates_length_of           :password, :min => 6

  after :create do
    self.token = SecureRandom.hex
  end

  def generate_token
    self.update!(:token => SecureRandom.hex)
  end

  def admin?
    self.permission_level == -1
  end

end

DataMapper.finalize
DataMapper.auto_upgrade!