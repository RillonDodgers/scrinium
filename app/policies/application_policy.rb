class ApplicationPolicy < ActionPolicy::Base
  authorize :user

  private

  def admin?
    user&.admin?
  end
end
