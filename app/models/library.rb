class Library < ApplicationRecord
  has_many :books, dependent: :destroy
  has_many :book_files, through: :books
  has_many :scan_runs, dependent: :destroy

  normalizes :name, with: ->(name) { name.strip }
  normalizes :root_path, with: ->(path) { path.strip.delete_suffix("/") }

  validates :name, presence: true, uniqueness: true
  validates :root_path, presence: true, uniqueness: true
end
