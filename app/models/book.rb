class Book < ApplicationRecord
  belongs_to :library
  belongs_to :author
  belongs_to :series, optional: true
  has_many :book_files, dependent: :destroy

  normalizes :title, with: ->(title) { title.strip }

  validates :title, presence: true, uniqueness: { scope: %i[ library_id author_id series_id ] }
end
