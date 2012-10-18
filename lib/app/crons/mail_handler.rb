# encoding: utf-8
require_relative '../models/init'
require 'mail'

MAIL_SUBJECT_KEYWORD = '[酒精檢測結果]'
IMG_DIR = 'photos'

def create_directory_if_not_exists(directory_name)
  Dir.mkdir(directory_name) unless File.exists?(directory_name)
  return directory_name
end

Mail.defaults do
  retriever_method :pop3, :address    => "msa.hinet.net",
                          :port       => 110,
                          :user_name  => 'pofeng.liu@msa.hinet.net',
                          :password   => 'cow3xiao',
                          :enable_ssl => false
end

Mail.find_and_delete(:what => :first, :order => :asc, :count => 50) { |mail| 
  mail.skip_deletion
  begin
    title = mail.subject
    unless title.include? MAIL_SUBJECT_KEYWORD then
      mail.skip_deletion
      puts "Not a relevent mail ~ #{title}"
      next
    end
    
    body = mail.text_part.decoded
=begin puts "##############\n"
    body.each_line do |l|
      r = l.split(':')
      puts "#{r[0].strip!}, #{r[1]}"
=end
    
    record = Hash.new
    tmp = []
    #title.sub(MAIL_SUBJECT_KEYWORD, '').split.each {|attr|
      #r = attr.split(':')
    body.each_line do |l|
      r = l.split(':')  
      #puts "#{r[0]}, #{r[1]}"
      case r[0].strip!
      when '員工編號'
        driver = Driver.first_or_create(:serial => Integer(r[1]))
        record[:driver] = driver
      when '員工姓名'
        # do nothing here 
      when '檢測結果'
        record[:value] = Float(r[1].strip!)
      when '日期', '時間'
        if r[0] == '日期' then tmp[0] = r[1].strip
        else tmp[1] = r[1] + ':' + r[2] + ':' + r[3].strip
        end
        if tmp.length == 2    
          record[:time] = Time.parse(tmp[0] + ' ' + tmp[1])
        end  
      when '檢測地點'
        site = Site.first_or_create({ :name => r[1].strip}, { :seq => 1})
        record[:site] = site   
      else
        raise "Bad email content which contains: #{r[0]} \n"
      end
    end
    # Handling attachment
    filename=""
    mail.attachments.each do | attachment |
      # Only to handle photo
      if (attachment.content_type.start_with?('image/'))
        filename = attachment.filename
        begin
          pathName = create_directory_if_not_exists(File.join(IMG_DIR, filename[0..1]))
          pathName = create_directory_if_not_exists(File.join(pathName, filename[2..3]))
          File.open(pathName + File::SEPARATOR + filename, "w+b", 0644) {|f| f.write attachment.body.decoded}
        rescue Exception => e
          #mail.skip_deletion
          raise "Unable to save data for imgage: #{filename} because #{e.message}"
        end
      end
    end # end attachment
    record[:image] = filename
    puts "[Debug] Inserting alcohol test record: #{record}"
    at = AlcoholTest.new(record)
    raise "Unable to save alcohol test record: #{at.errors.full_messages }" unless at.save
  rescue Exception => e
    mail.skip_deletion
    # [Todo] save maleformat email to file for further processing ~
    print "Error receiving email at " + Time.now.to_s + "::: " + e.message + "\n"   
  end 
} #end
puts 'No more mail found!'
