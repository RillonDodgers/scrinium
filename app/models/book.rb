class Book < ApplicationRecord
  belongs_to :library
  belongs_to :author
  belongs_to :series, optional: true
  has_many :book_files, dependent: :destroy
  has_many :book_metadata_tags, dependent: :destroy
  has_many :metadata_tags, through: :book_metadata_tags

  normalizes :title, with: ->(title) { title.strip }

  validates :title, presence: true, uniqueness: { scope: %i[ library_id author_id series_id ] }

  def preferred_cover_file
    present_book_files.find { |book_file| book_file.epub? && book_file.cover.attached? } ||
      present_book_files.find { |book_file| book_file.m4b? && book_file.cover.attached? } ||
      present_book_files.find(&:epub?) ||
      present_book_files.find(&:m4b?) ||
      available_book_files.first
  end

  def available_book_files
    book_files.sort_by { |book_file| [ book_file.epub? ? 0 : 1, book_file.relative_path ] }
  end

  def present_book_files
    available_book_files.select(&:status_present?)
  end

  def available_formats
    present_book_files.map(&:format).uniq
  end

  def metadata_tags_for(category_slug)
    book_metadata_tags
      .select { |book_metadata_tag| book_metadata_tag.metadata_tag.category_slug == category_slug }
      .sort_by { |book_metadata_tag| [ -book_metadata_tag.count, book_metadata_tag.metadata_tag.name.downcase ] }
  end
end
