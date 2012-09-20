class Driver
  include DataMapper::Resource

  property :id,   Integer, :key => true
  property :name, String, :required => true, :length => 20
end
