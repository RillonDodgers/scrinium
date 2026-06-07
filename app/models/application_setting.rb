class ApplicationSetting < ApplicationRecord
  encrypts :hardcover_api_token

  validates :singleton_guard, inclusion: { in: [ true ] }

  def self.current
    first_or_create!(singleton_guard: true)
  end
end
