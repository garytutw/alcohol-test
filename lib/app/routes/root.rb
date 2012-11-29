
class Application
  get '/' do
    login_required
    if current_user.nil?
    	haml :login
    elsif current_user.admin?
      redirect "/manager"
    elsif current_user.in_role? :hq
      redirect "/report"
    else
      puts #{current_user.site}
      redirect "/site/#{current_user.site_id}"
    end
  end
end
