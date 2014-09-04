class CreateMeetingExternalApprovers < ActiveRecord::Migration
  def change
    create_table :meeting_external_approvers do |t|
      t.string :meeting_container_type
      t.integer :meeting_container_id
      t.integer :contact_id
      t.integer :author_id
      t.datetime :created_on
    end
    add_index :meeting_external_approvers, :contact_id
    add_index :meeting_external_approvers, :author_id
  end
end
