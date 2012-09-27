
class SiteReport
  include DataMapper::Resource

  property :date, Date, :key => true, :unique => false
  belongs_to :site, :key => true

  property :total_tests, Integer
  property :operator_tests, Integer, :default => 0, :required => false
  property :trainees, Integer, :default => 0, :required => false
  property :pumpings, Integer, :default => 0, :required => false
  property :repeats, Integer, :default => 0, :required => false
  property :anomaly_tests, Integer
  property :created_at, DateTime
  property :updated_at, DateTime

  belongs_to :inputter, :model => User, :required => false
  belongs_to :auditor, :model => User, :required => false
  has n, :site_report_logs
end

