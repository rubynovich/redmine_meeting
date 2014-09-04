class CreateMeetingProtocols < ActiveRecord::Migration
  def change
    create_table :meeting_protocols do |t|
      t.time :start_time
      t.time :end_time
      t.references :meeting_agenda
      t.integer :asserter_id
      t.integer :external_asserter_id
      t.boolean :asserter_id_is_contact
      t.boolean :asserted, default: false
      t.datetime :asserted_on
      t.datetime :asserter_invite_on
      t.integer :meeting_company_id
      t.integer :author_id
      t.boolean :is_deleted, default: false
      t.datetime :created_on
    end
    add_index :meeting_protocols, :meeting_agenda_id
    add_index :meeting_protocols, :author_id
  end
end
