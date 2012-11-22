
class Application
  get '/anomaly/:site/:date', :auth => :hq do
    @site_name = params[:site]
    @date = parse_date(params[:date])
    sr = SiteReport.first(:date => @date, SiteReport.site.name => params[:site])
    @tests = sr.all_anomaly_tests
    show :anomaly, :layout => false
  end
end
