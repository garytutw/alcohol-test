
class Site
  include DataMapper::Resource

  property :id,     Serial
  property :name,   String, :required => true, :length => 40
  property :seq,    Integer, :required => true
  property :active, Boolean, :default => true

  has n, :alcohol_tests
  has n, :site_reports
  has n, :site_notifiers

  def update_report(date= Date.today - 1)
    dt_upper = ((date + 1).to_time - 1).to_datetime
    dt_lower = date.to_time.to_datetime
    total_tests = AlcoholTest.count(:site => self, :time => dt_lower..dt_upper)
    anomaly_tests = AlcoholTest.count(:site => self, :time => dt_lower..dt_upper,
                                      :value.gt => AlcoholTest::ANOMALY_BOUND)
    sr = site_reports.first(:date => date)
    if sr.nil?
      srl = SiteReportLog.new(:log => "Created by [user:system]")
      sr = SiteReport.new(:date => date, :site => self, :total_tests => total_tests,
                          :anomaly_tests => anomaly_tests)
      srl.save
      sr.save
    else
      log = ''
      if sr.total_tests != total_tests
        log << "[field:total_tests] updated from #{sr.total_tests} to #{total_tests} by [user:system]\n"
        sr.total_tests = total_tests
      end
      if sr.total_drivers != total_drivers
        log << "[field:total_drivers] updated from #{sr.total_drivers} to #{total_drivers} by [user:system]\n"
        sr.total_drivers = total_drivers
      end
      if sr.anomaly_tests != anomaly_tests
        log << "[field:anomaly_tests] updated from #{sr.anomaly_tests} to #{anomaly_tests} by [user:system]\n"
        sr.anomaly_tests = anomaly_tests
      end
      if log.length > 0
        srl = SiteReportLog.new(:log => log)
        srl.save
        sr.save
      end 
    end

  end
end
