#encoding: utf-8
class Application
  get '/site/:site/?:date?' do
    @date = params[:date] || Date.today - 1
    @site_name = params[:site]
    @site_report = SiteReport.first(:site => {:name => params[:site]}, :date => @date)
    @status_text = case @site_report.status
                   when 0 then '未輸入'
                   when 1 then '未核覆'
                   when 2 then '已核覆'
                   end
    show :site_report
  end

  post '/site/:site/:date' do
    @date = params[:date]
    @site_name = params[:site]
    @errors = validate(params["site_report"])
    if @errors.size > 0
      @status_text = params[:status]
      @site_report = OpenStruct.new params[:site_report]
    else
      @site_report = SiteReport.first(:site => {:name => params[:site]}, :date => @date)
      log = ''
      [:operator_tests, :trainees, :pumpings, :repeats].each do |k|
        ov = @site_report.send(k)
        nv = params["site_report"][k.to_s].to_i
        puts "#{k}: ov=#{ov}, nv=#{nv}"
        if ov != nv
          log << "[field:#{k.to_s}]: #{ov} => #{nv}\n"
          @site_report.send("#{k.to_s}=", nv)
        end
      end
      if log.size
        @site_report.save
        srl = SiteReportLog.new(:log => log)
        srl.site_report = @site_report
        srl.save
      end
      @status_text = case @site_report.status
                     when 0 then '未輸入'
                     when 1 then '未核覆'
                     when 2 then '已核覆'
                     end
    end
    show :site_report
  end

  def validate(params)
    errors = {}
    errors[:operator_tests] = "調度測試 必須是整數" unless is_integer(params["operator_tests"])
    errors[:trainees] = "見習 必須是整數" unless is_integer(params["trainees"])
    errors[:pumpings] = "抽班 必須是整數" unless is_integer(params["pumpings"])
    errors[:repeats] = "重覆 必須是整數" unless is_integer(params["repeats"])
    errors
  end
  
  def is_integer(s)
     !!(s.strip =~ /^[0-9]+$/)
  end
end
