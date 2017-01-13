class AlcoholTest

  include DataMapper::Resource

  property :id,   Serial
  property :value, Decimal, :required => true, :precision => 4, :scale => 3
  property :time, DateTime, :required => true
  property :image, FilePath, :required => true
  property :latitude, Float
  property :longitude, Float
  property :location, String, :length => 40

  belongs_to :driver
  belongs_to :site

  after :create do
    d = time.to_date
    SiteReport.get(d, site.id) ||
    SiteReport.new(:date => d, :site => site).save
  end
end
