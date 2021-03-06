#encoding: utf-8
require 'bcrypt'

class Application
  @@app_config = YAML.load_file('config/app.yaml')
  def find_users level
    @users = repository(:default).adapter.select(
      "select * from users where permission_level < #{level} order by site_id ")
  end
  
	get "/manager", :auth => [:admin, :auditor] do
    haml :manager
  end
  
  get '/manager/serial_inquiry', :auth => :admin do
    term = params['name_startsWith'] + '%'
    @users = repository(:default).adapter.select(
      "select * from users where id like '#{term}' or name like '#{term}' order by id LIMIT 12")
    new_rows = @users.map {|row| Hash[:id => row.id, :name => row.name]}
    {:users => new_rows}.to_json
  end
  
  get "/manager/edit", :auth => [:admin, :hq, :auditor, :operator] do
    if @current_user.permission_level == -1 # admin
      #@users = User.all(:permission_level.lt => 2)
      #haml :user_list
      if (params.has_key? "id")
        @users = User.all(:id => params[:id])
        haml :user_list 
      else
        haml :user_search
      end  
    elsif @current_user.permission_level == 1 # site admin
      @users = Site.all(:id => @current_user.sites.map{|s| s.id}).users(:permission_level.gte => 1, :order => [ :permission_level.asc ])
      #@users = User.all(:permission_level.gte => 1, :sites => Array(@current_user.sites), :enabled => true, :order => [ :permission_level.asc ])
      # Above is not working due to after migrate site_id column if User can't be removed, and :sites will try to associate this old column
      haml :user_list
    else
      @users = User.all(:id => @current_user.id)
      haml :user_list      
    end
  	
  end
  
  get "/manager/edit/:id", :auth => [:admin, :hq, :auditor, :operator] do
      @user = User.first(:id => params[:id])
      @multi = @user.sites.map.detect {|s| @@app_config['enable_multi_site'].include?(s.id)}
      if @user.nil?
        flash[:error] = "此員工帳號不存在"
        redirect "/manager/edit"
      else
        param = nil
        @sites ||= Site.all(:id.gte => 1, :order => [ :seq.asc ]) if @site.nil?
        haml :user
      end

  end
  
  post "/manager/edit", :auth => [:admin, :hq, :auditor, :operator] do
  	user = User.first(:id => params[:user][:id])
  	if user.nil? # incase booked url to delete user account twice!
  	  redirect "/manager/edit"
  	end
  	if params.has_key? "update"
  	  params[:user]["enabled"] = true
  		#params[:user]["site"] = Site.first(:id => params[:user][:site])
      user_attributes = params[:user]
      if params[:user][:password] == "" && params[:user][:password_confirmation] == ""# not set in web page, keep the original passwd
        user_attributes.delete("password")
        user_attributes.delete("password_confirmation")
      end
      if params[:user]["deputy"].nil?
        params[:user]["deputy"] = false
      end
      if user.update(params[:user])
        if params[:sites] != nil
          user.site_users.all.destroy!
          params[:sites].map{|s| user.sites << Site.get(s)}
        end
        user.save
        flash[:notice] = "使用者 #{user.name} 更新完成！"
        redirect "/manager/edit"
      else #replace original dm-validation errors with Chinese ones
        if user.errors[:password].to_s.include? "does not match"
          user.errors[:password] = ["密碼與密碼確認不符！"]
        else user.errors[:password].to_s.include? "characters long"
          user.errors[:password] = ["密碼長度至少需為四個字元！"] 
        end
        flash[:error] = user.errors.full_messages    
        redirect "/manager/edit/#{user.id}"
      end
  	elsif params.has_key? "delete"
  	  # if user.destroy
  	  if user.update(:enabled => false)
  	  	flash[:notice] = "使用者 #{user.name} 刪除成功！" 
      	redirect "/manager/edit" 
  	  else 
  	  	flash[:error] = user.errors.full_messages    
      	redirect "/manager/edit?" + hash_to_query_string(params[:user])
  		end
  	else # do 'cancel' here
  		redirect "/manager/edit"
  	end
  end
  
  get "/manager/signup", :auth => [:admin, :auditor] do
  	@sites ||= Site.all(:id.gte => 1) if @site.nil?
  	if params.empty?
    	haml :signup
    else # redirect from signup POST
    	haml :signup, :locals => params
  	end	
  end

  post "/manager/signup", :auth => [:admin, :auditor] do
    if params.has_key? "cancel"
      redirect "/manager/edit"
    end
  	#params[:user]["site"] = Site.first(:id => params[:user][:site])
    user = User.create(params[:user])
    if user.save
      params[:sites].map{|s| user.sites << Site.get(s)}
      user.save
      flash[:notice] = "員工帳號 #{user.name} 新增完成！" 
      #session[:user] = user.token # no need to switch to the newly created user
      redirect "/manager/edit" 
    else
      # replace original dm-validation errors with Chinese ones
      unless user.errors[:password].nil?
        if user.errors[:password].to_s.include? "does not match"
          user.errors[:password] = ["密碼與密碼確認不符！"]
        elsif user.errors[:password].to_s.include? "characters long"
          user.errors[:password] = ["密碼長度至少需為四個字元！"]
        end
      end
      unless user.errors[:id].nil?
        if user.errors[:id].to_s.include? "blank"
          user.errors[:id] = ["員工序號不可為空值！"]
        elsif user.errors[:id].to_s.include? "taken"
          user.errors[:id] = ["此員工序號已存在系統帳號中！"]
        end
      end
      unless user.errors[:name].nil?
        if user.errors[:name].to_s.include? "blank"
          user.errors[:name] = ["員工姓名不可為空值！"]
        end
      end
    	flash[:error] = user.errors.full_messages    
      session[:errors] = user.errors.full_messages
      redirect "/manager/signup?" + hash_to_query_string(params[:user])
    end
  end

  get "/login" do
    if current_user && session[:redirect_to] != '/manager'
      redirect_last
    else
      haml :login
    end
  end

  post "/login" do
    if user = User.first(:id => params[:id], :enabled => true)
      if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
        session[:user] = user.token 
        response.set_cookie "user", {:value => user.token, :expires => (Time.now + 24*60*60)}
        redirect_last
      else
        flash[:error] = "員工序號與密碼不符"
        redirect "/login?id=#{params[:id]}"
      end
    else
      flash[:error] = "員工帳號不存在"
      redirect "/login?id=#{params[:id]}"
    end
  end

  get "/logout" do
    response.delete_cookie "user"
    session[:user] = nil
    session[:redirect_to] = nil
    flash[:notice] = "帳號已成功登出"
    session.clear
    redirect "/login"
  end
  
  get "/manager/sitemgr", :auth => :admin do
    @sites = Site.all(:id.gte => 1, :order => [ :seq.asc ])
    haml :site_mgr
  end
  
  post "/manager/sitemgr/:site_id/:checked", :auth => :admin do
    deact_site = Site.get(params[:site_id])
    @sites = Site.all(:id.gte => 1)
    if params[:checked] == 'true'
      deact_site.active = false
      org_seq = deact_site.seq
      @sites.each do |site|
        if site.seq > org_seq
          site.seq = site.seq - 1
          if !site.save
            puts site.errors.full_messages
          end
        end  
      end
      # move the deactive site to the last of the sequence
      deact_site.seq = @sites.size 
      if !deact_site.save
        puts deact_site.errors.full_messages
      end
    elsif
      deact_site.active = true
      org_seq = repository(:default).adapter.select(
      "select min(seq) from sites where active='f'")[0]
      @sites.each do |site|
        if site.seq >= org_seq
          site.seq = site.seq + 1
          if !site.save
            puts site.errors.full_messages
          end
        end  
      end
      deact_site.seq = org_seq
      if !deact_site.save
        puts deact_site.errors.full_messages
      end
    end # end if - elsif
  end
  
  post "/manager/site/sort", :auth => :admin do
  	@sites ||= Site.all(:id.gte => 1) if @site.nil?
    @sites.each do |site|
      site.seq = params['site'].index(site.id.to_s) + 1
      if !site.save
        puts site.errors.full_messages
      end
    end
  end
  
  post "/manager/sitenew", :auth => :admin do
    @sites ||= @sites = Site.all(:id.gte => 0) if @site.nil?
    if params.length > 0 # new site
      site = Site.create(:name => params[:site].strip, :seq => @sites.length + 1)
      if site.save
        redirect "/manager/sitemgr"
      else
        if site.errors[:name].to_s.include? "blank"
          site.errors[:name] = ["分站名稱不可為空值！"]
        elsif site.errors[:name].to_s.include? "already taken"
          site.errors[:name] = ["分站名稱不可重複！"]  
        end
        flash[:error] = site.errors.full_messages
        redirect "/manager/sitemgr"     
      end
    end  
  end
  
  get '/manager/notifier/:site_id', :auth => :admin do
    @site = Site.get(params[:site_id])
    @notifiers = @site.site_notifiers
    show :site_notifiers, :layout => false
  end

  post '/manager/notifier/:site_id/:nid', :auth => :admin do
    if params[:nid] == 'newEmail'
      sn = SiteNotifier.create(:site_id => params[:site_id], :email => params[:email])
      sn.id.to_s 
    else
      sn = SiteNotifier.get(params[:nid].to_i)
      sn.email = params[:email]
      sn.save
      sn.id.to_s
    end
  end
  
  delete '/manager/notifier/:site_id/:nid', :auth => :admin do
    SiteNotifier.get(params[:nid]).destroy
    ""
  end

end
