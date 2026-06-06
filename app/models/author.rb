class Author < ApplicationRecord
  has_many :books, dependent: :restrict_with_exception
  has_many :series, dependent: :restrict_with_exception

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: true
end
