
class Application
  get '/report', :auth => :hq do
    dates = repository(:default).adapter.select(
      "select distinct date from site_reports order by date desc limit 1")
    redirect "/report/#{dates[0]}"
  end

  get '/report/:date', :auth => :hq do
    @available_dates = repository(:default).adapter.select(
      "select distinct date from site_reports order by date desc limit 7")
    @date = Date.strptime(params[:date], '%Y-%m-%d')
    @reports = SiteReport.all(:date => @date,
      :order => [SiteReport.site.seq.asc],
      :links => [SiteReport.relationships[:site].inverse])
    show :report
  end
end
