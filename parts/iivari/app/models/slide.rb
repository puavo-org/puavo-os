class Slide < ActiveRecord::Base
  belongs_to :channel

  def slide_html
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    # FIXME, set path prefix
    view.render( :partial => "screen/client_" + self.template,
                 :format => :html,
                 :locals => { :slide => self } )
  end
end
