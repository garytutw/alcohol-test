class Application
  get '/report/:site/:date' do

    @site = Site.first(:name => params[:site])
    @date = Date.strptime(params[:date], '%Y-%m-%d')
    @report = SiteReport.first(:site => @site, :date => @date)

  end
end
