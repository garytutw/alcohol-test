class Site
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String, :required => true, :length => 40
  property :seq,    Integer, :required => true

  has n, :alcohol_tests
end
