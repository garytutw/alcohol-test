
class SiteReport
  include DataMapper::Resource

  @@app_config = YAML.load_file('config/app.yaml')

  property :date, Date, :key => true, :unique => false
  belongs_to :site, :key => true

#  property :total_tests, Integer
  property :total_trips, Integer, :default => 0, :required => false
  property :operator_tests, Integer, :default => 0, :required => false
  property :trainees, Integer, :default => 0, :required => false
  property :pumpings, Integer, :default => 0, :required => false
  property :repeats, Integer, :default => 0, :required => false
  property :comment, String, :length => 40, :required => false
#  property :anomaly_tests, Integer
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

  def total_tests
    return @tt if @tt
    dt_upper = ((date + 1).to_time - 1).to_datetime
    dt_lower = date.to_time.to_datetime
    @tt = AlcoholTest.count(:site_id => site_id, :time => dt_lower..dt_upper)
  end

  def anomaly_tests
    return @at if @at
    dt_upper = ((date + 1).to_time - 1).to_datetime
    dt_lower = date.to_time.to_datetime
    @at = AlcoholTest.count(:site_id => site_id, :time => dt_lower..dt_upper,
                            :value.gt => @@app_config["anomaly_bound"])
  end
  
  def all_anomaly_tests
    dt_upper = ((date + 1).to_time - 1).to_datetime
    dt_lower = date.to_time.to_datetime
    AlcoholTest.all(:site_id => site_id, :time => dt_lower..dt_upper,
                    :value.gt => @@app_config["anomaly_bound"]).sort_by {|t| t.time}
  end

  def inputter_name
    inputter.nil? ? "" : inputter.name
  end
  
  def auditor_name
    auditor.nil? ? "" : auditor.name
  end

  def consistent
    total_tests == total_trips + operator_tests + trainees + pumpings + repeats
  end
end

