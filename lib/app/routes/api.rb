
class Application

  put '/ALCDATA.TDB' do
    filename = 'lib/app/public/ALCDATA.TDB'
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

end
