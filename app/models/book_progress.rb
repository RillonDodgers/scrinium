class BookProgress < ApplicationRecord
  belongs_to :user
  belongs_to :book
  belongs_to :epub_book_file, class_name: "BookFile", optional: true
  belongs_to :m4b_book_file, class_name: "BookFile", optional: true

  enum :last_mode, { read: "read", listen: "listen", read_and_listen: "read_and_listen" }, prefix: true, validate: { allow_nil: true }

  validates :audio_position_seconds, numericality: { greater_than_or_equal_to: 0 }
  validates :user_id, uniqueness: { scope: :book_id }
end
