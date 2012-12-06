require 'bcrypt'

class Application
  def find_users level
    @users = repository(:default).adapter.select(
      "select * from users where permission_level < #{level} order by site_id ")
  end
  
	get "/manager", :auth => [:admin, :auditor] do
    haml :manager
  end
  
  get "/manager/edit", :auth => [:admin, :auditor] do
    if @current_user.permission_level == -1 # admin
      @users = repository(:default).adapter.select(
      "select * from users where permission_level < 2 order by site_id ")
      haml :user_list  
    else
      @users = repository(:default).adapter.select(
      "select * from users where permission_level = 2 and site_id = #{@current_user.site_id}")
      haml :user_list    
    end
  	
  end
  
  get "/manager/edit/:id", :auth => [:admin, :auditor] do
     @user = User.first(:id => params[:id])
      # p @user
      if @user.nil?
        flash[:error] = "No user found!"
        redirect "/manager/edit"
      else
        param = nil
        @sites ||= Site.all if @site.nil?
        haml :user
      end
  end
  
  post "/manager/edit", :auth => [:admin, :auditor] do
  	user = User.first(:id => params[:user][:id])
  	if params.has_key? "update"
  		params[:user]["site"] = Site.first(:id => params[:user][:site])
      user_attributes = params[:user]
      if params[:user][:password] == "" # not set in web page
        user_attributes.delete("password")
        user_attributes.delete("password_confirmation")
      end
      if user.update(user_attributes)
        flash[:notice] = "User #{user.name} updated."
        redirect '/manager/edit'
      else
        flash[:error] = user.errors.full_messages
        redirect "/manager/edit"
      end
  	elsif params.has_key? "delete"
  	  if user.destroy
  	  	flash[:notice] = "Delete #{user.name} successfully!" 
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
  	@sites ||= Site.all if @site.nil?
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
  	params[:user]["site"] = Site.first(:id => params[:user][:site])
    user = User.create(params[:user])
    if user.save
      flash[:notice] = "User account #{user.name} created!" 
      #session[:user] = user.token # no need to switch to the newly created user
      redirect "/manager/edit" 
    else
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
    if user = User.first(:id => params[:id])
      if user.password_hash == BCrypt::Engine.hash_secret(params[:password], user.password_salt)
        session[:user] = user.token 
        response.set_cookie "user", {:value => user.token, :expires => (Time.now + 24*60*60)} if params[:remember_me]
        redirect_last
      else
        flash[:error] = "ID/Password combination does not match"
        redirect "/login?id=#{params[:id]}"
      end
    else
      flash[:error] = "That serial ID is not recognised"
      redirect "/login?id=#{params[:id]}"
    end
  end

  get "/logout" do
    if current_user
      @current_user.generate_token
      response.delete_cookie "user"
      session[:user] = nil
      session[:redirect_to] = nil
      flash[:notie] = "Successfully logged out"
    end
    redirect "/login"
  end
  
  get "/manager/sitemgr", :auth => :admin do
    @sites = Site.all(:order => [ :seq.asc ])
    haml :site_mgr
  end
  
  post "/site/sort" do
  	@sites ||= Site.all if @site.nil?
    @sites.each do |site|
      site.seq = params['site'].index(site.id.to_s) + 1
      if !site.save
        puts site.errors.full_messages
      end
    end
  end
  
  post "/manager/sitenew", :auth => :admin do
    @sites ||= Site.all if @site.nil?
    if params.length > 0 # new site
      site = Site.create(:name => params[:site], :seq => @sites.length + 1)
      if site.save
        redirect "/manager/sitemgr"
      else
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
