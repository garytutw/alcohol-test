
class Application
  get '/' do
    login_required
    if current_user.admin?
      redirect "/manager"
    elsif current_user.in_role? :hq
      redirect "/report"
    else
      redirect "/site/#{current_user.site.name}"
    end
  end
end
