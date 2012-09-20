class Driver
  include DataMapper::Resource

  property :id,     Serial
  property :serial, Integer, :unique_index => true
  property :name,   String, :default => '', :length => 20

  has n, :alcohol_tests
end
