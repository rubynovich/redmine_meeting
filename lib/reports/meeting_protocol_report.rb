# encoding: utf-8

class MeetingProtocolReport < Prawn::Document

  include Redmine::I18n

  def to_pdf(object)
    set_font_families

    # Логотип и информация о компании
    if object.meeting_company.present?
      print_company_info(object.meeting_company)
      move_down 20
    end

    # Информация с согласующими и утверждающим
    asserter = object.asserter_id_is_contact? ? object.external_asserter : object.asserter
#    print_approval_list(object.meeting_approvers.open.map(&:person)+object.external_approvers, asserter)
    print_approval_list(object.meeting_approvers.deleted(false), asserter, object.asserted_on)
    move_down 5

    # Информация о совещании (номер) и протоколе (дата, время, место, адрес и тд)
    print_protocol_fields(object)
    move_down 10

    # Фактические участники совещания
    print_meeting_participators(object.meeting_agenda.users, object.users)
    move_down 10

    # Внешние участники совещания
    if (object.meeting_agenda.contacts | object.contacts).any?
      print_meeting_contacts(object.meeting_agenda.contacts, object.contacts)
      move_down 10
    end

    # Решения по вопросам
    print_meeting_answers(object.all_meeting_answers)

    # Счетчик страниц
    set_page_counter

    render
  end

private

  def set_page_counter
    page_options = {
      align: :right,
      start_count_at: 1,
      size: 8,
      family: 'Callibri',
      at: [bounds.right - 100, 0],
      inline_format: true
    }

    number_pages l(:label_page_counter), page_options
  end

  def set_font_families
    fonts_path = "#{Rails.root}/plugins/redmine_meeting/lib/fonts/"
    font_families.update(
           "FreeSans" => { bold: fonts_path + "FreeSansBold.ttf",
                           italic: fonts_path + "FreeSansOblique.ttf",
                           bold_italic: fonts_path + "FreeSansBoldOblique.ttf",
                           normal: fonts_path + "FreeSans.ttf" },
            "Calibri" => { bold: fonts_path + "CALIBRIB.TTF",
                           italic: fonts_path + "CALIBRII.TTF",
                           bold_italic: fonts_path + "CALIBRIZ.TTF",
                           normal: fonts_path + "CALIBRI.TTF"}
                           )
    font "Calibri"
  end

  def print_company_info(company)
    begin
      image open(company.logo), vposition: :top, position: :center, fit: [400, 580]
    rescue
    end

    company_details = [
      [
        company.fact_address,
        company.phone,
        company.fax,
        company.email
      ], [
        company.okpo,
        company.inn,
        company.kpp,
        company.ogrn
      ]
    ]

    table company_details do |t|
        t.position = :center
        t.header = false
        t.width = 580
        t.cells.border_width = 0
        t.cells.size = 8
        t.cells.align = :center
        t.cells.valign = :middle
        t.cells.padding = [0,10,0,10]
        t.before_rendering_page do |page|
          page.row(0).border_top_width = 3
        end
    end
  end

  def print_approval_list(approvers, asserter, asserted_on)
    approvers_label = if approvers.present?
      {content: "«#{l(:label_meeting_protocol_head_agreed)}»"}
    else
      nil
    end

    approval_list = [[
      approvers_label,
      nil,
      {content: "«#{l(:label_meeting_protocol_head_approved)}»"}
    ]]

    default_field = "_________________"
    agreed_list = if approvers.present?
      approvers.map{ |o| "#{o.person}/________/#{format_date(o.approved_on)}"}
    else
      [""]
    end
    approved_list = (asserter.present? ? [asserter] : [default_field]).
      map{ |o| "#{o}/________/#{format_date(asserted_on)}"}

    approval_list += agreed_list.zip([], approved_list)

    table approval_list do |t|
      t.position = :center
      t.header = false
      t.width = 580
      t.cells.border_width = 0
      t.cells.size = 10
      t.cells.style = :italic
#        t.cells.align = :right
      t.cells.valign = :middle
      t.cells.padding = [5,20,0,20]
      t.before_rendering_page do |page|
        page.column(0).align = :left
        page.column(2).align = :right
        page.row(0).font_style = :bold
      end
    end
  end

  def print_protocol_fields(object)
#    text((object.is_external? ? l(:label_external_meeting_protocol) : l(:label_meeting_protocol)) + " №#{object.id}", style: :bold, size: 22, align: :center)
    text(l(:label_meeting_protocol) + " №#{object.id}", style: :bold, size: 22, align: :center)
#    move_down 10

    text("<b>#{l(:field_subject)}:</b> <i>#{object.subject}</i>", size: 10, inline_format: true)
    if object.is_external?
      text("<b>#{l(:field_external_company)}:</b> <i>#{object.external_company}</i>", size: 10, inline_format: true)
      text("<b>#{l(:field_address)}:</b> <i>#{object.place}</i>", size: 10, inline_format: true)
    elsif object.meeting_company.present? && object.meeting_company.fact_address.present?
      text("<b>#{l(:field_place)}:</b> <i>#{object.meeting_company.fact_address}, #{object.place}</i>", size: 10, inline_format: true)
    else
      text("<b>#{l(:field_place)}:</b> <i>#{object.place}</i>", size: 10, inline_format: true)
    end
    text("<b>#{l(:field_meet_on)}:</b> <i>#{format_date(object.meet_on)}</i>", size: 10, inline_format: true)
    move_up 13
    text("<b>#{l(:label_meeting_agenda_time)}:</b> <i>#{format_time(object.start_time, false)} - #{format_time(object.end_time, false)}</i>", size: 10, inline_format: true, align: :center)
    move_up 13
    text("<b>#{l(:field_meeting_agenda)}:</b> <i>№#{object.meeting_agenda_id}</i>", size: 10, inline_format: true, align: :right)
    text("<b>#{l(:field_author)}:</b> <i>#{object.author}</i>", size: 10, inline_format: true)
  end

  def print_meeting_participators(agenda_users, protocol_users)
    text("#{l(:field_meeting_participators)}:", size: 13, style: :bold)
    move_down 5

    meeting_participators = (agenda_users|protocol_users).compact.sort_by(&:name).map do |user|
      member = agenda_users.include?(user)
      participator = protocol_users.include?(user)
      status = if member && participator
        l(:label_meeting_member_present)
      elsif member
        l(:label_meeting_member_blank)
      elsif participator
        l(:label_meeting_member_extra)
      end

      [
        (user.company rescue ""),
        (user.job_title rescue ""),
        user.name,
        status
      ]
    end

    meeting_participators.insert(0,[l(:field_company), l(:field_job_title), l(:field_member), l(:label_meeting_invite_status)])

    table meeting_participators, header: true, width: 540, position: :center, column_widths: {0 => 100, 3 => 100} do |t|
        t.cells.size = 10
        t.cells.padding = [0,10,5,10]
        t.cells.align = :center
        t.cells.border_width = 0.01
#        t.cells.border_lines = [:dotted]*4
        t.before_rendering_page do |page|
          page.row(0).font_style = :bold
          page.row(0).background_color = "DDDDDD"
          page.row(0).align = :center
        end
    end
  end

  def print_meeting_contacts(agenda_contacts, protocol_contacts)
    text("#{l(:field_meeting_contacts)}:", size: 13, style: :bold)
    move_down 5

    meeting_contacts = (agenda_contacts|protocol_contacts).compact.sort_by(&:name).map do |contact|
      member = agenda_contacts.include?(contact)
      participator = protocol_contacts.include?(contact)
      status = if member && participator
        l(:label_meeting_member_present)
      elsif member
        l(:label_meeting_member_blank)
      elsif participator
        l(:label_meeting_member_extra)
      end

      [
        (contact.company rescue ""),
        (contact.job_title rescue ""),
        contact.name,
        status
      ]
    end

    meeting_contacts.insert(0,[l(:field_company), l(:field_job_title), l(:field_member), l(:label_meeting_invite_status)])

    table meeting_contacts, header: true, width: 540, position: :center, column_widths: {0 => 100, 3 => 100} do |t|
        t.cells.size = 10
        t.cells.padding = [0,10,5,10]
        t.cells.align = :center
#        t.cells.border_lines = [:dotted]*4
        t.cells.border_width = 0.01
        t.before_rendering_page do |page|
          page.row(0).font_style = :bold
          page.row(0).background_color = "DDDDDD"
          page.row(0).align = :center
        end
    end
  end

  def print_meeting_answers(answers)
    text("#{l(:label_meeting_answer_plural)}:", size: 13, style: :bold)
#    move_down 5
    project_index = 0
    answers.group_by(&:project).sort_by{ |project, answers| project.to_s }.each do |project, answers|
      project_index += 1
      move_down 5
      text("#{project_index}. #{project || l(:label_without_project)}", size: 11, style: :bold, align: :center)
#      move_down 5
      answers.each_with_index do |object, index|
        text("<b>#{project_index}.#{index+1}. #{l(:label_meeting_question)}:</b> <i>#{object.meeting_question}</i>", size: 10, inline_format: true)
        if object.reporter_id_is_contact?
          text("<b>#{l(:label_meeting_answer_reporter)}:</b> <i>#{object.external_reporter}</i>", size: 10, inline_format: true)
        else
          text("<b>#{l(:label_meeting_answer_reporter)}:</b> <i>#{object.reporter}</i>", size: 10, inline_format: true)
        end
        if object.question_issue.present?
          move_up 13
          text("<b>#{l(:field_issue)}:</b> <i>№#{object.question_issue.id}</i>", size: 10, inline_format: true, align: :center)
        end
        text("<b>#{l(:label_meeting_answer)}:</b> <i>#{object.description.gsub(/[\n\r]+/, "\n").gsub(/[\t ]+/, " ")}</i>", size: 10, inline_format: true)
        if object.user_id_is_contact?
          text("<b>#{l(:label_meeting_answer_user)}:</b> <i>#{object.external_user}</i>", size: 10, inline_format: true)
        else
          if object.issue_id.present?
            text("<b>#{object.issue.tracker} №#{object.issue_id}:</b> <i>#{object.issue.subject} (#{object.status})</i>", size: 10, inline_format: true)
          end
          text("<b>#{l(:label_meeting_answer_user)}:</b> <i>#{object.user}</i>", size: 10, inline_format: true)
        end
#        move_up 13
#        text("<b>#{l(:field_start_date)}:</b> <i>#{format_date(object.start_date)}</i>", size: 10, inline_format: true, align: :center)
        move_up 13
        text("<b>#{l(:field_due_date)}:</b> <i>#{format_date(object.due_date)}</i>", size: 10, inline_format: true, align: :right)
        move_down 10
      end
    end
  end
end
