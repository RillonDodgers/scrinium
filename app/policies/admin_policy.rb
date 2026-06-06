class AdminPolicy < ApplicationPolicy
  def manage?
    admin?
  end
end
