
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
  
  # 0 -> 未輸入
  # 1 -> 未核覆
  # 2 -> 已核覆
  def status
    if !inputter.nil? or !auditor.nil?
      if auditor.nil?
        1
      else
        2
      end
    else
      0
    end
  end

  def total_cars
    status == 0 ? "N/A" : total_tests - operator_tests
  end

  def inputter_name
    inputter.nil? ? "" : inputter.name
  end
  
  def auditor_name
    auditor.nil? ? "" : auditor.name
  end
end

