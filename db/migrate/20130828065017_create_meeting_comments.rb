class CreateMeetingComments < ActiveRecord::Migration
  def change
    create_table :meeting_comments do |t|
      t.references :meeting_answer
      t.references :author
      t.text :note
      t.datetime :created_on
    end
    add_index :meeting_comments, :meeting_answer_id
    add_index :meeting_comments, :author_id
  end
end
