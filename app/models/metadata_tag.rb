class MetadataTag < ApplicationRecord
  has_many :book_metadata_tags, dependent: :destroy
  has_many :books, through: :book_metadata_tags

  normalizes :category, :category_slug, :name, :slug, with: ->(value) { value.to_s.strip }

  validates :category, :category_slug, :name, :slug, presence: true
  validates :hardcover_tag_id, uniqueness: true, allow_nil: true
  validates :slug, uniqueness: { scope: :category_slug }
end
