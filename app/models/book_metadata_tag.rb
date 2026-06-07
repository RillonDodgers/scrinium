class BookMetadataTag < ApplicationRecord
  belongs_to :book
  belongs_to :metadata_tag

  validates :metadata_tag_id, uniqueness: { scope: :book_id }
  validates :count, numericality: { greater_than_or_equal_to: 0 }
  validates :spoiler_ratio, numericality: { greater_than_or_equal_to: 0 }
end
