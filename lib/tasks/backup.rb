
system "mkdir backups" unless Dir.exist? "backups"

desc 'Backup db/photos'
task :backup do
  today = Time.now.strftime('%Y%m%d')
  filename = "backups/backup_#{today}.tgz"
  if File.exist? filename 
    puts "Backup file already exist: #{filename}"
  else
    puts "Backup for #{today}"
    system "tar czf #{filename} database.db photos/"
  end
  # only keep 7 backups
  bs = Dir.glob('backups/backup_*.tgz').sort
  if bs.length > 7
    bs.slice(0, bs.length-7).each do |f|
      puts "Deleting #{f}"
      system "rm -f #{f}"
    end
  end
end

def yesno
  begin
    system("stty raw -echo")
    str = STDIN.getc
  ensure
    system("stty -raw echo")
  end
  if str == "Y" or str == 'y'
    return true
  elsif str == "N" or str == 'n'
    return false
  else
    raise "Invalid character."
  end
end

desc 'Restore db/photos'
task :restore do
  bs = Dir.glob('backups/backup_*.tgz').sort
  lastdate = bs.last[15, 8]
  print "Restore from the lastest backup: #{lastdate} [y/n]? "
  if (yesno)
    puts "\nRestoring from the last backup: #{lastdate}"
    system "tar xzf #{bs.last}"
  end
end
