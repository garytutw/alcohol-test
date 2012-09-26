
class Application
  get '/report/:date' do
    @date = Date.strptime(params[:date], '%Y-%m-%d')
    @reports = SiteReport.all(:date => @date,
      :order => [SiteReport.site.seq.asc],
      :links => [SiteReport.relationships[:site].inverse])
    show :report
  end
end
