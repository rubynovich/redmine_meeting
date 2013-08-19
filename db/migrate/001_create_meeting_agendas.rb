class CreateMeetingAgendas < ActiveRecord::Migration
  def change
    create_table :meeting_agendas do |t|
      t.string :subject
      t.string :place
      t.date :meet_on
      t.time :start_time
      t.time :end_time
      t.integer :author_id
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_agendas, :author_id
  end
end
