
class Application

  get '/search', :auth => :hq do
    @available_dates, @max_date, @min_date = calc_dates
    @sites = Site.all(:order => [:seq.asc])

    show :search
  end
end
