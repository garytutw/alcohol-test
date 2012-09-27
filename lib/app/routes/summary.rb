#encoding: utf-8
class Application
  get '/summary/:site/?:date?' do
    @date = params[:date] || Date.today - 1
    @site = params[:site]
    @summary = SiteReport.first(:site => {:name => params[:site]}, :date => @date)
    @status = 0   # not updated yet
    @status_text = "未輸入"
    @submit_text = "更改"
    if !@summary.inputter.nil? or !@summary.auditor.nil?
      if @summary.auditor.nil?
        @status = 1  # updated but not audited
        @status_text = "未覆核"
      else
        @status = 2  # audited
        @status_text = "已覆核"
      end
    end
    show :summary
  end
end
