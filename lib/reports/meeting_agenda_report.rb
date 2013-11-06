# encoding: utf-8

class MeetingAgendaReport < Prawn::Document

  include Redmine::I18n

  # unloadable

  # def initialize(invoice)
  #   @invoice = invoice
  #
  # end

  def to_pdf(agenda)
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

    image open(agenda.meeting_company.logo), vposition: :top, position: :center, fit: [400, 580]

    company_details = [
      [
        agenda.meeting_company.fact_address,
        agenda.meeting_company.phone,
        agenda.meeting_company.fax,
        agenda.meeting_company.email
      ], [
        agenda.meeting_company.okpo,
        agenda.meeting_company.inn,
        agenda.meeting_company.kpp,
        agenda.meeting_company.ogrn
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
    move_down 20

    approval_list = [[
      {content: "«#{l(:label_meeting_protocol_head_agreed)}»"},
      nil,
      {content: "«#{l(:label_meeting_protocol_head_approved)}»"}
    ]]

    default_field = "_________________"
    agreed_list = (agenda.approvers.present? ? agenda.approvers : [default_field]).map{ |o| "#{o}/________/"}
    approved_list = (agenda.asserter.present? ? [agenda.asserter] : [default_field]).map{ |o| "#{o}/________/"}

    approval_list += agreed_list.zip([], approved_list)

    table approval_list do |t|
        t.position = :center
        t.header = false
        t.width = 580
        t.cells.border_width = 1
        t.cells.size = 10
        t.cells.style = :italic
        t.cells.align = :right
        t.cells.valign = :middle
        t.cells.padding = [0,0,0,0]
        t.before_rendering_page do |page|
          page.row(0).align = :center
          page.row(0).style = :bold
        end
    end
    move_down 20

    text(l(:label_meeting_agenda) + " №#{agenda.id}", style: :bold, size: 22, align: :center)

    move_down 10

    text("<b>#{l(:field_subject)}:</b> <i>#{agenda.subject}</i>", size: 10, inline_format: true)

#    text l(:label_invoice), style: :bold, size: 30
#    lines = invoice.lines.map do |line|
#      [
#        line.position,
#        line.description,
#        line.quantity,
#        line.price,
#        line.total
#      ]
#    end
#    lines.insert(0,[l(:field_invoice_line_position),
#                   l(:field_invoice_line_description),
#                   l(:field_invoice_line_quantity),
#                   l(:field_invoice_line_price),
#                   l(:field_invoice_line_total) ])

#    table lines,
#      :row_colors => ["FFFFFF", "DDDDDD"],
#      :header => true

    render
  end
end
