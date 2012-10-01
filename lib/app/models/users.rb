require 'bcrypt'

class User 
  include DataMapper::Resource
  
  attr_accessor :password, :password_confirmation
  property :id, String, :key => true
  property :name, String, :required => true, :length => 10
  property :password_hash,  Text  
  property :password_salt,  Text
  property :created_at, DateTime
  property :token, String
  property :permission_level, Integer, :default => 2
  belongs_to :site, :required => false
  
  validates_presence_of         :password, :unless => Proc.new { |t| t.password_hash }
  validates_presence_of         :password_confirmation, :unless => Proc.new { |t| t.password_hash }
  validates_confirmation_of     :password
  #validates_length_of           :password, :min => 6
	
  def password=(pass)
    @password = pass
    self.password_salt = BCrypt::Engine.generate_salt if !self.password_salt
    self.password_hash = BCrypt::Engine.hash_secret(@password, self.password_salt)
  end
  
  after :create do
    self.token = SecureRandom.hex
  end

  def generate_token
    self.update!(:token => SecureRandom.hex)
  end

  def admin?
    self.permission_level == -1
  end
  
  # check if (ACL) auth role is correct
  def in_role? role
    case role
    when :admin
    	return admin?
    when :operator
    	return self.permission_level == 2
    when :auditor
    	return self.permission_level == 1
    when :hq                      
    	return self.permission_level == 0
    else
    	return false
  	end
  end

end

