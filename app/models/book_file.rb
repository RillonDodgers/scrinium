class BookFile < ApplicationRecord
  belongs_to :book
  has_one_attached :cover

  enum :format, { epub: "epub", m4b: "m4b" }, validate: true
  enum :status, { present: "present", missing: "missing" }, prefix: true, validate: true

  normalizes :relative_path, with: ->(path) { path.strip }

  validates :relative_path, presence: true, uniqueness: { scope: %i[ book_id format ] }
  validates :size_bytes, numericality: { greater_than_or_equal_to: 0 }
  validates :mtime, presence: true

  def absolute_path
    File.join(book.library.root_path, relative_path)
  end

  def duration_label
    return if duration_seconds.blank?

    total_seconds = duration_seconds.to_i
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60

    if hours.positive?
      "#{hours}h #{minutes}m"
    else
      "#{minutes}m"
    end
  end

  def chapter_count
    chapters.size
  end
end
