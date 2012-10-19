
class Application
  get '/report', :auth => :hq do
    d = SiteReport.first(:order => [:date.desc]).date
    redirect "/report/#{d}"
  end

  get '/report/:date', :auth => :hq do
    @available_dates = repository(:default).adapter.select(
      "select distinct date from site_reports order by date desc limit 7")
    @date = Date.strptime(params[:date], '%Y-%m-%d')
    dt_upper = ((@date + 1).to_time - 1).to_datetime
    dt_lower = @date.to_time.to_datetime
    @reports = []
    Site.all(:order => [:seq.asc]).each do |s|
      sr = SiteReport.get(@date, s.id)
      sr.total_tests = AlcoholTest.count(:site => s, :time => dt_lower..dt_upper)
      next if sr.total_tests == 0
      sr.anomaly_tests = AlcoholTest.count(:site => s, :time => dt_lower..dt_upper,
                                        :value.gt => AlcoholTest::ANOMALY_BOUND)
      @reports << sr
    end
    show :report
  end
end
