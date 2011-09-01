module ApplicationHelper

  def schools_menu
    content_tag :ul do
      @schools.map do |school|
        content_tag :li do
          link_to( school.name,  channels_path(school.puavo_id) )
        end
      end.join.html_safe
    end.html_safe
  end
end
