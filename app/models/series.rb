class Series < ApplicationRecord
  belongs_to :author
  has_many :books, dependent: :nullify

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, uniqueness: { scope: :author_id }
  validates :hardcover_id, uniqueness: true, allow_nil: true
end
