#encoding: utf-8
class Application
  def available_dates(site)
    repository(:default).adapter.select(
      "select date from site_reports, sites where sites.name='#{site}' and sites.id=site_reports.site_id order by date desc limit 7")
  end

  get '/site/:site/?:date?', :auth => [:hq, :auditor, :operator] do
    @date = params[:date] || Date.today - 1
    @site_name = params[:site]
    @site_report = SiteReport.first(:site => {:name => params[:site]}, :date => @date) ||
      SiteReport.first(:site => {:name => params[:site]}, :order => [:date.desc], :limit => 1)
    @date = @site_report.date
    @available_dates = available_dates(params[:site])
    @status_text = case @site_report.status
                   when 0 then '未輸入'
                   when 1 then '未核覆'
                   when 2 then '已核覆'
                   end
    show :site_report
  end

  post '/site/:site/:date', :auth => [:hq, :auditor, :operator] do
    @date = params[:date]
    @available_dates = available_dates(params[:site])
    @site_name = params[:site]
    @site_report = SiteReport.first(:site => {:name => params[:site]}, :date => @date)
    @errors = authorize_update(current_user, @site_report)
    @errors.merge! validate(params["site_report"])
    if @errors.size > 0
      @status_text = params[:status]
      @site_report = OpenStruct.new params[:site_report]
    else
      log = ''
      [:total_trips, :operator_tests, :trainees, :pumpings, :repeats].each do |k|
        ov = @site_report.send(k)
        nv = params["site_report"][k.to_s].to_i
        if ov != nv
          log << "  [field:#{k.to_s}]: #{ov} => #{nv}\n"
          @site_report.send("#{k.to_s}=", nv)
        end
      end
      if log.size
        @site_report.save
        log.insert(0, "[user:#{current_user.id}] 更新\n")
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

  def authorize_update(current_user, report)
    errors = {}
    case report.status
    when 0 # 未輸入
      report.inputter = current_user
      report.auditor = current_user unless current_user.in_role? :operator
    when 1 # 未核覆
      report.auditor = current_user unless current_user.in_role? :operator
    when 2 # 已核覆
      errors[:authorize] = "無法更改已核覆報告" if current_user.in_role? :operator
    end
    errors
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
