class AddAsserterToMeetingProtocols < ActiveRecord::Migration
  def change
    begin
      add_column :meeting_protocols, :asserter_id, :integer
    rescue
    end
  end
end
