class AlcoholTest
  
  ANOMALY_BOUND = 0.01

  include DataMapper::Resource

  property :id,   Serial
  property :value, Decimal, :required => true, :precision => 4, :scale => 3
  property :time, DateTime, :required => true
  property :image, FilePath, :required => true

  belongs_to :driver
  belongs_to :site

  after :create do
    d = time.to_date
    SiteReport.get(d, site.id) ||
    SiteReport.new(:date => d, :site => site).save
  end
end
