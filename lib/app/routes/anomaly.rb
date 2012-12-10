
class Application
  get '/anomaly/:site_id/:date', :auth => :hq do
    @date = parse_date(params[:date])
    sr = SiteReport.first(:date => @date, :site_id => params[:site_id])
    @tests = sr.all_anomaly_tests
    show :anomaly, :layout => false
  end
end
