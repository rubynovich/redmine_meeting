class AddAssertedOnToMeetingProtocols < ActiveRecord::Migration
  def change
    add_column :meeting_protocols, :asserted_on, :datetime rescue nil
  end
end
