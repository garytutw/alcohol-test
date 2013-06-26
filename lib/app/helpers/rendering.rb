# encoding: utf-8
module Helpers
  def stylesheets(*sheets)
    sheets.each {|sheet|
      haml_tag(:link, :href => path("#{sheet}.css"),
               :type => "text/css", :rel => "stylesheet")
    }
  end

  def show(view, options={})
    haml view, options
  end

  def checkbox(name, condition, extras={})
    attrs = {:name => name, :type => "checkbox", :value => 1}
    attrs[:checked] = !!condition
    attrs.update(extras)
  end

  include Rack::Utils
  alias :h :escape_html

  @@field_names = {
    "total_trips" => "總班次數",
    "operator_tests" => "調度測試",
    "trainees" => "見習",
    "pumpings" => "抽班",
    "repeats" => "重複",
  }
  def log_content(change)
    name = @@field_names[change["f"]] || change["f"]
    "欄位: #{name}, #{change["ov"]} ==> #{change["nv"]}"
  end

  def format_time(time)
    time.strftime('%H:%M:%S')
  end
  
  def format_datetime(time)
    time.strftime('%Y-%m-%d %H:%M:%S')
  end
end
