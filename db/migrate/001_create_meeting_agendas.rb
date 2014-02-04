class CreateMeetingAgendas < ActiveRecord::Migration
  def change
    create_table :meeting_agendas do |t|
      t.string :subject
      t.string :place
      t.string :address
      t.string :external_place_type
      t.integer :priority_id
      t.references :meeting_room_reserve
      t.boolean :is_external, default: false
      t.integer :external_company_id
      t.integer :asserter_id
      t.integer :external_asserter_id
      t.boolean :asserter_id_is_contact
      t.boolean :asserted, default: false
      t.datetime :asserter_invite_on
      t.integer :meeting_company_id
      t.date :meet_on
      t.time :start_time
      t.time :end_time
      t.integer :author_id
      t.boolean :is_deleted, default: false
      t.datetime :created_on
    end
    add_index :meeting_agendas, :priority_id
    add_index :meeting_agendas, :author_id
    add_index :meeting_agendas, :external_company_id
  end
end
