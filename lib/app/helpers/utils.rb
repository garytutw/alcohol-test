module Helpers
  def parse_date(dstr)
    Date.strptime(dstr, '%Y-%m-%d')
  end
end
