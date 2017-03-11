module Helpers
  def parse_date(dstr)
    return dstr.to_date if dstr.is_a?(DateTime)
    Date.strptime(dstr, '%Y-%m-%d')
  end
end
