class AddPriorityIdToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :priority_id, :integer
    add_index :meeting_agendas, :priority_id
  end
end
