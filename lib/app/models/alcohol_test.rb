class AlcoholTest
  include DataMapper::Resource

  property :id,   Serial
  property :value, Decimal, :required => true, :precision => 5, :scale => 2
  property :time, DateTime, :required => true
  property :image, FilePath, :required => true

  belongs_to :driver
  belongs_to :site
end
