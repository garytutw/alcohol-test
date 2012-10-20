
class Application
  get '/report', :auth => :hq do
    d = SiteReport.first(:order => [:date.desc]).date
    redirect "/report/#{d}"
  end

  def parse_date(dstr)
    Date.strptime(dstr, '%Y-%m-%d')
  end

  def calc_dates
    available_dates = repository(:default).adapter.select(
      "select distinct date from site_reports order by date desc limit 7")
    min_date = parse_date(available_dates[0]).prev_year
    min_date_in_db = SiteReport.first(:order => [:date.asc]).date
    min_date = min_date_in_db if min_date <  min_date_in_db
    [available_dates, available_dates[0], min_date.to_s]
  end

  get '/report/:date', :auth => :hq do
    @available_dates, @max_date, @min_date = calc_dates
    @date = parse_date(params[:date])
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
