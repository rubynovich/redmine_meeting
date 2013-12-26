class AddIsDeletedToMeetingAgendas < ActiveRecord::Migration
  def change
    add_column :meeting_agendas, :is_deleted, :boolean, default: false
  end
end
