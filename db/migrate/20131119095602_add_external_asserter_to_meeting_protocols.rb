class AddExternalAsserterToMeetingProtocols < ActiveRecord::Migration
  def change
    #add_column :meeting_protocols, :asserter_id_is_contact, :boolean
    add_column :meeting_protocols, :external_asserter_id, :integer
  end
end
