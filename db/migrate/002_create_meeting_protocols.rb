class CreateMeetingProtocols < ActiveRecord::Migration
  def change
    create_table :meeting_protocols do |t|
      t.references :meeting_agenda
      t.integer :author_id
      t.datetime :created_on
      t.datetime :updated_on
    end
    add_index :meeting_protocols, :meeting_agenda_id
    add_index :meeting_protocols, :author_id
  end
end
