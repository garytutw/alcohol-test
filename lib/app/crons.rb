scheduler = Rufus::Scheduler.start_new

# gen reports at 2/4/6 AM every day
scheduler.cron "0 2,4,6 * * *" do
  Site.all.each do |s|
    s.update_report(Date.today -d)
  end
end
