
Struct.new('Result', :total, :size, :results)

class Application
  register Sinatra::Paginate

  get '/search', :auth => :hq do
    @available_dates, @max_date, @min_date = calc_dates
    @sites = Site.all(:order => [:seq.asc])

    show :search
  end

  get '/search/bysite', :auth => :hq do
    date = parse_date params[:date]
    dt_upper = ((date + 1).to_time - 1).to_datetime
    dt_lower = date.to_time.to_datetime
    limit = 20
    page = [params[:page].to_i - 1, 0].max
    @tests = AlcoholTest.all(:site_id => params[:site_id],
                             :time => dt_lower..dt_upper,
                             :offset => page * limit,
                             :limit => limit,
                             :order => [:time.asc])
    totals  = AlcoholTest.count(:site_id => params[:site_id],
                               :time => dt_lower..dt_upper)
    @result = Struct::Result.new(totals, @tests.count, @tests)
    show :search_results, :layout => false 
  end

end
