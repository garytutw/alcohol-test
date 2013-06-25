
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
  
  get '/search/serial_inquiry', :auth => :hq do
    @drivers = repository(:default).adapter.select(
      "select * from drivers where serial like '#{params['name_startsWith']}%' order by serial LIMIT 12")
    new_rows = @drivers.map {|row| Hash[:id => row.serial, :name => row.name]}
    {:drivers => new_rows}.to_json
  end
  
  get '/search/byserial', :auth => :hq do
    date1 = parse_date params[:date1]
    date2 = parse_date params[:date2]
    dt_upper = ((date2 + 1).to_time - 1).to_datetime
    dt_lower = date1.to_time.to_datetime
    limit = 20
    page = [params[:page].to_i - 1, 0].max
    driver = Driver.first(:serial => params[:emp_id])
    @tests = AlcoholTest.all(:driver_id => driver.id, 
                             :time => dt_lower..dt_upper,
                             :offset => page * limit,
                             :limit => limit,
                             :order => [:time.asc])
    totals  = AlcoholTest.count(:driver_id => '#{params[:emp_id]}',
                               :time => dt_lower..dt_upper)
    @result = Struct::Result.new(totals, @tests.count, @tests)
    show :search_results, :layout => false 
  end
end
