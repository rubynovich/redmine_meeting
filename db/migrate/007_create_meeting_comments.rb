class CreateMeetingComments < ActiveRecord::Migration
  def change
    create_table :meeting_comments do |t|
      t.integer :meeting_container_id, null: false
      t.string  :meeting_container_type, null: false
      t.references :author
      t.text :note
      t.datetime :created_on
    end
    add_index :meeting_comments, :author_id
  end
end
