AgendaPolicy = Struct.new(:user, :agenda) do
  def create_protocol?
    (meeting_manager? || admin?) &&
    agenda_is_running? &&
    !agenda.is_deleted? &&
    asserted?
  end

  def send_invites?
    (admin? || (meeting_manager? && author?)) &&
    agenda_is_running? &&
    !agenda.is_deleted? &&
    asserted?
  end

  alias :resend_invites? :send_invites?

  def show?
    admin? || (
      meeting_manager? && (
        author? ||
        member? ||
        approver? ||
        asserter?
      )
    )
  end

  def create?
    admin? || meeting_manager?
  end

  alias :new? :create?

  def update?
    (admin? ||
      (meeting_manager? &&
        (author? || approver? || asserter?))) &&
    (agenda.meeting_protocol.blank? ||
      (agenda.meeting_protocol.present? && agenda.meeting_protocol.is_deleted?)) &&
    (agenda.meet_on >= Date.today) &&
    !agenda.is_deleted? &&
    (!asserted? || not_assertable?)
  end

  alias :edit? :update?

  def destroy?
    (admin? || (meeting_manager? && author?)) &&
    agenda.meeting_protocol.blank? &&
    !agenda.is_deleted? &&
    (!asserted? || not_assertable?)
  end

#  def can_show_protocol?(protocol)
#    admin? || (meeting_manager? && (author?(protocol) || member?(protocol) || approver?(protocol) || watcher?(protocol) || asserter?(protocol)))
#  end

  def assert?
    asserter? && !agenda.asserted? && approved?
  end

  def send_asserter_invite?
    (admin? || (meeting_manager? && author?)) &&
    !agenda.asserter_id_is_contact? &&
    agenda.asserter.present? &&
    approvable? &&
    (agenda.asserter_id != user.id)
  end

  def restore?
    (admin? || (meeting_manager? && author?)) &&
    agenda.is_deleted?
  end

private
  def meeting_member?
    user.meeting_member?
  end

  def meeting_manager?
    user.meeting_manager?
  end

  def meeting_participator?
    user.meeting_participator?
  end

  def admin?
    user.admin?
  end

  def author?
    agenda.author_id == user.id
  end

  def member?
    agenda.user_ids.include?(user.id)
  end

  def approver?
    agenda.approver_ids.include?(user.id)
  end

  def asserter?
    (agenda.asserter_id == user.id) && !agenda.asserter_id_is_contact?
  end

  def approved?
    approvers = agenda.meeting_approvers.reject(&:deleted)
    (approvers.present? && approvers.all?(&:approved?)) || approvers.blank?
  end

  def asserted?
    (agenda.asserted? ||
      (agenda.asserter_id_is_contact? && approved?))
  end

  def not_assertable?
    !approvable? && agenda.asserter_id_is_contact?
  end

  def approvable?
    agenda.meeting_approvers.open.present?
  end

  def watcher?
    agenda.watcher_ids.include?(user.id)
  end

  def agenda_is_running?
    agenda.meet_on.present? && (
      (agenda.meet_on > Date.today) || (
        (agenda.meet_on == Date.today) &&
        (agenda.start_time.seconds_since_midnight > Time.now.seconds_since_midnight)
      )
    )
  end
end
