class Screen < ActiveRecord::Base

  def screen_html
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    # FIXME, set path prefix
    view.render( :partial => "screens/client_" + self.template,
                 :format => :html,
                 :locals => { :screen => self } )
  end
end
