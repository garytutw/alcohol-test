require 'bcrypt'

class Application

  get "/" do     
    haml :index
  end
	
	get "/manager", :auth => :admin do
    haml :home
  end
  
  get "/manager/edit", :auth => :admin do
  	if params.empty?
    	haml :user
    else
    	@user = User.first(:id => params[:user][:id])
    	p @user
    	if @user.nil?
	  		flash[:error] = "No user found!"
	      redirect "/manager/edit"
  		else
  			param = nil
  			@sites ||= Site.all if @site.nil?
    		haml :user
    	end
  	end	
  end
  
  post "/manager/edit", :auth => :admin do
  	user = User.first(:id => params[:user][:id])
  	if params.has_key? "update"
  		params[:user]["site"] = Site.first(params[:user][:site])
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
  
  get "/manager/signup", :auth => :admin do
  	@sites ||= Site.all if @site.nil?
  	if params.empty?
    	haml :signup
    else # redirect from signup POST
    	haml :signup, :locals => params
  	end	
  end

  post "/manager/signup", :auth => :admin do
  	params[:user]["site"] = Site.first(params[:user][:site])
    user = User.create(params[:user])
    #user.password_salt = BCrypt::Engine.generate_salt
    #user.password_hash = BCrypt::Engine.hash_secret(params[:user][:password], user.password_salt)
    if user.save
      flash[:notice] = "User account #{user.name} created!" 
      #session[:user] = user.token # no need to switch to the newly created user
      redirect "/" 
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
        response.set_cookie "user", {:value => user.token, :expires => (Time.now + 52*7*24*60*60)} if params[:remember_me]
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
  
  # for site reporting
  get "/site", :auth => [:user, :manager] do
    haml :home
  end
  
  #=============== testing only ===================
  get "/secret" do
    login_required
    "This is a secret secret"
  end

  get "/supersecret" do
    if current_user
      admin_required
      "Well done on being super special. You're a star!"
    else
      haml :login
    end

  end

  get "/personal/:id" do
    is_owner? params[:id]
    "<pre>id: #{current_user.id}\nname: #{current_user.name}\nadmin? #{current_user.admin}</pre>"
  end
end
