
class SiteNotifier
  include DataMapper::Resource

  property :id,     Serial
  property :email,  String, :required => true, :length => 40

  belong_to :site

end
