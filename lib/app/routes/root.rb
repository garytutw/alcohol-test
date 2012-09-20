
class Application < Sinatra::Base

  get '/' do
    @title = "Home"
    haml :home
  end

end
