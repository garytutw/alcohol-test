
class SiteReportLog
  include DataMapper::Resource

  property :id, Serial
  property :log, String, :required => true, :length => 1024
  property :created_at, DateTime

  belongs_to :site_report
end
