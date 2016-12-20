# encoding: utf-8
require 'RMagick'
require 'mail'
require 'securerandom'

class Application

  IMG_DIR = 'photos'
  @@abncfg = YAML.load_file('config/app.yaml')

  put '/MASTER.TDB' do
    filename = 'lib/app/public/MASTER.TDB'
    username = request.env['HTTP_USERNAME']
    password = request.env['HTTP_PASSWORD']
    if user = User.first(:id => username) and user.password_hash == BCrypt::Engine.hash_secret(password, user.password_salt)
      if user.admin? or user.in_role? :hq
        File.open(filename, 'wb') {|f| f.write(request.body.read)}
        status 200
      else
        status 401
      end
    else
      status 401
    end
  end

  post '/check_alc' do
    site = Site.first_or_create({:name => params["site"].strip}, {:seq => 1})
    driver = Driver.first_or_create({:serial => params["id"]}, {:name => params["name"]})
    if (driver.name != params["name"]) # client typing error
      puts "Driver with serial #{params["serial"]} name does not match, update to: #{params["name"]}"
      driver.update(:name => params["name"])
    end
    if AlcoholTest.first({:driver => driver, :site => site, :time => DateTime.iso8601(params["timestamp"])})
      json :result => "exist"
    else
      json :result => "notexist"
    end
  end

  def create_directory_if_not_exists(directory_name)
    Dir.mkdir(directory_name) unless File.exists?(directory_name)
    return directory_name
  end

  def check_anomaly(record, limit, rule)
    puts "[Debug] Checking anomaly rules: record[:value] > limit => #{record[:value] > limit} && !!(record[:driver].serial.to_s =~ rule) => #{!!(record[:driver].serial.to_s =~ rule)}"
    begin
      if record[:value] > limit && !!(record[:driver].serial.to_s =~ rule)
        filename = record[:image]
        cclist = ''
        SiteNotifier.all(:site_id => record[:site].id).each do |notify|
          cclist += notify.email + ","
        end
        cclist.chomp(",")
        @email = Mail.new do
          from    'alcoholtest@ubus.com.tw'
          to      cclist
          subject "[異常酒精檢測結果] 員工編號:#{record[:driver].serial} 員工姓名:#{record[:driver].name}" +
          " 檢測結果:#{record[:value]} 日期時間:#{record[:time]} 檢測地點:#{record[:site].name}"
          text_part do
            content_type 'text/plain; charset=UTF-8'
            body    "酒測圖片如附件"
          end
          add_file "#{File.join(File.dirname(__FILE__), '../../..', IMG_DIR, filename[0..1], filename[2..3], filename)}" if filename
        end
        @email.deliver!
        puts "[Debug] Send Anomaly Mail Done!!"
      end # end if
    rescue Exception => e
      # do nothing ~
      print "Error sending anomaly email at " + Time.now.to_s + "::: " + e.message + "\n"
    end
  end

  def add_alc(driver, site, timestamp, value, filename)
    record = Hash.new
    record[:driver] = driver
    record[:site] = site
    record[:time] = timestamp
    record[:value] = value
    record[:image] = filename
    at = AlcoholTest.first({:driver => driver, :site => site, :time => record[:time]})
    if not at
      at = AlcoholTest.new(record)
      if at.save
        check_anomaly(record, Float(@@abncfg["anomaly_bound"]), Regexp.new(@@abncfg["tester_serial"]))
        return 200
      else
        return 500
      end
    else
      return 500
    end
  end

  post '/add_alc' do
    site = Site.first_or_create({:name => params["site"].strip}, {:seq => 1})
    driver = Driver.first_or_create({:serial => params["id"]}, {:name => params["name"]})
    if (driver.name != params["name"]) # client typing error
      puts "Driver with serial #{params["serial"]} name does not match, update to: #{params["name"]}"
      driver.update(:name => params["name"])
    end
    filename = params["filename"]
    if filename && params["image"]
      begin
        create_directory_if_not_exists(File.join(IMG_DIR,''))
        pathName = create_directory_if_not_exists(File.join(IMG_DIR, filename[0..1]))
        pathName = create_directory_if_not_exists(File.join(pathName, filename[2..3]))
        img = Magick::Image.read_inline(params["image"])[0]
        bg = Magick::Image.new(190, 50) {self.background_color = '#a0a0a0'}
        txt = Magick::Draw.new
        bg.annotate(txt, 0, 0, 0, 0, "酒測值: #{"%.3f" % params["alc"].to_f}") {
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
        status 500
        puts "Unable to save data for image: #{filename} because #{e.message}"
        return
      end
    end
    filename = filename || "NA"
    timestamp = DateTime.iso8601(params["timestamp"])
    value = BigDecimal(params["alc"])
    code = add_alc(driver, site, timestamp, value, filename)
    status code
  end

  mFields = {
    'ID' => :id,
    '檢測結果' => :value,
    '日期' => :date,
    '時間' => :time
  }
  post '/addm' do
    data = {}
    body = params['BODY']
    body.split(/\r?\n|\r/).each do |line|
      m = /^([^\t]+)\t?:(.+)$/.match(line)
      next if not m
      next if not mFields[m[1]]
      data[mFields[m[1]]] = m[2].strip
    end
    site = Site.first_or_create({:name => @@abncfg["mobile_site"].strip}, {:seq => 1})
    driver = Driver.first_or_create({:serial => data[:id]})
    timestamp = "#{data[:date].gsub(/\//, '-')}T#{data[:time]}+08:00"
    value = BigDecimal(data[:value])
    filename = ''
    if params['FILE']
      begin
        filename = "#{SecureRandom.urlsafe_base64}.jpg"
        tempfile = params['FILE'][:tempfile]
        img = tempfile.read
        create_directory_if_not_exists(File.join(IMG_DIR,''))
        pathName = create_directory_if_not_exists(File.join(IMG_DIR, filename[0..1]))
        pathName = create_directory_if_not_exists(File.join(pathName, filename[2..3]))
        File.open(pathName + File::SEPARATOR + filename, "w+b", 0644) {|f| f.write img}
      rescue
        status 500
        puts "Unable to save data for image: #{filename} because #{e.message}"
        return '1'
      end
    end
    add_alc(driver, site, timestamp, value, filename)
    '0'
  end
end
