class CreateMeetingCompanies < ActiveRecord::Migration
  def up
    create_table :meeting_companies do |t|
      t.string :name
      t.string :logo
      t.string :fact_address
      t.string :okpo
      t.string :ogrn
      t.string :inn
      t.string :kpp
      t.string :phone
      t.string :fax
      t.string :email
      t.string :site
    end
    I18n.locale = :ru
    I18n.t(:objects_meeting_company).map{ |h| MeetingCompany.create(h) }
  end
  def down
    drop_table :meeting_companies
  end
end
