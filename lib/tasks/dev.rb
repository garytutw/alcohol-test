
namespace :dev do
  desc 'Start in development mode'
  task :start do
    system 'thin -e development start'
  end
end

