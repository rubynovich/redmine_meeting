class CreateMeetingProtocols < ActiveRecord::Migration
  def change
    create_table :meeting_protocols do |t|
      t.time :start_time
      t.time :end_time
      t.references :meeting_agenda
      t.integer :author_id
      t.datetime :created_on
    end
    add_index :meeting_protocols, :meeting_agenda_id
    add_index :meeting_protocols, :author_id
  end
end
