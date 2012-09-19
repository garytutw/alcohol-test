
module Helpers
#  module Rendering
    def stylesheets(*sheets)
      sheets.each {|sheet|
        haml_tag(:link, :href => path("#{sheet}.css"),
                 :type => "text/css", :rel => "stylesheet")
      }
    end

    def show(view, options={})
      haml view
    end

    def checkbox(name, condition, extras={})
      attrs = {:name => name, :type => "checkbox", :value => 1}
      attrs[:checked] = !!condition
      attrs.update(extras)
    end
#  end

  include Rack::Utils
  alias :h :escape_html

end
