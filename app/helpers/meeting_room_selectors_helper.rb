module MeetingRoomSelectorsHelper
  def principals_radio_button_tags(name, principals)
    s = ''
    principals.each do |principal|
      s << "<label>#{ radio_button_tag name, principal.id, false, id: nil } #{h principal}</label>\n"
    end
    s.html_safe
  end
end
