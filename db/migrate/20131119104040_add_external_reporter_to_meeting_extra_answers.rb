class AddExternalReporterToMeetingExtraAnswers < ActiveRecord::Migration
  def change
    add_column :meeting_extra_answers, :reporter_id_is_contact, :boolean
    add_column :meeting_extra_answers, :external_reporter_id, :integer
  end
end
