class AddAsserterToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :asserter_id, :integer rescue nil
  end
end
