class AddAssertedOnToMeetingProtocols < ActiveRecord::Migration
  def change
    begin
      add_column :meeting_protocols, :asserted_on, :datetime
    rescue
    end
  end
end
