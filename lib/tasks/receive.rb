# encoding: utf-8
require_relative '../app/models/init'
require 'mail'
require 'RMagick'

MAIL_SUBJECT_KEYWORD = '[酒精檢測結果]'
IMG_DIR = 'photos'

@config = YAML.load_file('config/mail.yaml')
@abncfg = YAML.load_file('config/app.yaml')
def create_directory_if_not_exists(directory_name)
    Dir.mkdir(directory_name) unless File.exists?(directory_name)
    return directory_name
end
def get_recipients site_id
    cclist = ''
    SiteNotifier.all(:site_id => site_id).each do |notify|
      cclist += notify.email + ","
    end
    cclist.chomp(",")
end

def check_anomaly(record, limit, rule)
    puts "[Debug] Checking anomaly rules: record[:value] > limit => #{record[:value] > limit} && !!(record[:driver].serial.to_s =~ rule) => #{!!(record[:driver].serial.to_s =~ rule)}"
    begin
      if record[:value] > limit && !!(record[:driver].serial.to_s =~ rule)
        filename = record[:image]
        @email = Mail.new do
          from    'alcoholtest@ubus.com.tw'
          to      get_recipients record[:site].id
          subject "[異常酒精檢測結果] 員工編號:#{record[:driver].serial} 員工姓名:#{record[:driver].name}" +
          " 檢測結果:#{record[:value]} 日期時間:#{record[:time]} 檢測地點:#{record[:site].name}"
          text_part do
            content_type 'text/plain; charset=UTF-8'
            body    "酒測圖片如附件"
          end
          add_file "#{File.join(File.dirname(__FILE__), '../..', IMG_DIR, filename[0..1], filename[2..3], filename)}"
        end
        @email.deliver!
        puts "[Debug] Send Anomaly Mail Done!!"
      end # end if
    rescue Exception => e
      # do nothing ~
      print "Error sending anomaly email at " + Time.now.to_s + "::: " + e.message + "\n"
    end
end

def convgeo(dms)
  d = dms.split('.')
  d[0].to_f + d[1].to_f/60 + d[2].to_f/3600
end

def mail_handler mail
  begin
    begin
      body = mail.text_part.decoded
    rescue Exception => e
      raise "Unable to parse mail body with subject: #{mail.subject}"
    end
      record = Hash.new
      tester = Hash.new
      tmp = []

      body.each_line do |l|
        r = l.split(':')
        r.each {|v| v.strip!} # remove empty trail
        case r[0]
        when '員工編號'
          tester[:serial] = r[1]
        when '員工姓名'
          tester[:name] = r[1]
        when '檢測結果'
          record[:value] = BigDecimal(r[1])
        when '日期', '時間'
          if r[0] == '日期' then tmp[0] = r[1]
          else tmp[1] = r[1] + ':' + r[2] + ':' + r[3]
          end
          if tmp.length == 2
            record[:time] = Time.parse(tmp[0] + ' ' + tmp[1])
          end
        when '緯度'
          record[:latitude] = convgeo(r[1])
        when '經度'
          record[:longitude] = convgeo(r[1])
        when '檢測地點'
          if record[:latitude] then
            record[:site] = Site.first_or_create({:name => @abncfg["mobile_site"].strip}, {:seq => 1})
            record[:location] = r[1]
          else
            record[:site] = Site.first_or_create({ :name => r[1]}, { :seq => 1})
          end
        else
          puts "[MAIL] Bad email content which contains: #{r[0]} \n"
          # raise "Bad email content which contains: #{r[0]} \n"
        end
      end
      # Handling attachment
      filename=""
      mail.attachments.each do | attachment |
        # Only to handle photo
        if (attachment.content_type.start_with?('image/'))
          filename = attachment.filename
          begin
            create_directory_if_not_exists(File.join(IMG_DIR,''))
            pathName = create_directory_if_not_exists(File.join(IMG_DIR, filename[0..1]))
            pathName = create_directory_if_not_exists(File.join(pathName, filename[2..3]))
            img = Magick::Image.from_blob(attachment.body.decoded).first
            bg = Magick::Image.new(190, 50) {self.background_color = '#a0a0a0'}
            txt = Magick::Draw.new
            bg.annotate(txt, 0, 0, 0, 0, "酒測值: #{"%.3f" % record[:value].to_f}") {
              txt.font = 'lib/app/fonts/DroidSansFallback.ttf'
              txt.gravity = Magick::CenterGravity
              txt.pointsize = 30
              txt.stroke = 'transparent'
              txt.fill = '#ff0000'
              txt.font_weight = Magick::BoldWeight
            }
            img = img.dissolve(bg, 1, 1, Magick::SouthEastGravity)
            File.open(pathName + File::SEPARATOR + filename, "w+b", 0644) {|f| f.write img.to_blob}
          rescue Exception => e
            raise "Unable to save data for imgage: #{filename} because #{e.message}"
          end
        end
      end # end attachment

      #record[:driver] = Driver.first_or_create(tester)
      the_driver = Driver.first_or_create({:serial =>  tester[:serial]}, {:name =>  tester[:name]}) # require serial match only
      if (the_driver.name != tester[:name]) # client typing error
        puts "Driver with serial #{tester[:serial]} name does not match, update to: #{tester[:name]}"
        the_driver.update(:name => tester[:name])
      end
      record[:driver] = the_driver
      record[:image] = filename
      # puts "[DB] Inserting alcohol test record: #{record}"
      at = AlcoholTest.new(record)
      if at.save
        # check anomaly of this received mail
        check_anomaly(record, Float(@abncfg["anomaly_bound"]), Regexp.new(@abncfg["tester_serial"]))

        if @config['delete_from_server']
          mail.mark_for_delete = true    # delete the mail from server
        end
      else
        raise "Unable to save alcohol test record: #{at.errors.full_messages }"
      end
    rescue Exception => e
      # [Todo] save maleformat email to file for further processing ~
      mail.skip_deletion
      print "Error receiving email at " + Time.now.to_s + "::: " + e.message + "\n"
      #next
    end
end

desc 'Import alcohol tests from local file server'
task :import, :file do |t, args|
  mail_file = args[:file] || ''
  puts "Block called !" + mail_file
  amail = Mail.read(mail_file)
  mail_handler amail
end

desc 'Receiving alcohol tests from POP3 server'
task :receive do

  config = YAML.load_file('config/mail.yaml')
  Mail.defaults do
    retriever_method :pop3,
      :address    => config["address"],
      :port       => config["port"],
      :user_name  => config["user_name"],
      :password   => config["password"],
      :enable_ssl => config["enable_ssl"]
  end

  puts "Mail server connected, start to check new mails ..."
  Mail.find_and_delete(:count => 'ALL', :what => :first, :order => :asc, :keys => MAIL_SUBJECT_KEYWORD) { |themail|
    themail.mark_for_delete = false
    mail_handler themail
  } #end
  puts 'Done! No more mail found!'
end
