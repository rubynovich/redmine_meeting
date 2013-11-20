class AddExternalReporterToMeetingAnswers < ActiveRecord::Migration
  def change
    add_column :meeting_answers, :reporter_id_is_contact, :boolean
    add_column :meeting_answers, :external_reporter_id, :integer
  end
end
