class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :book_progresses, dependent: :destroy

  enum :role, { admin: "admin", user: "user" }, default: :user
  enum :library_media_filter, { ebooks: "ebooks", audiobooks: "audiobooks", both: "both" }, prefix: :library_media_filter, default: :ebooks

  normalizes :email, with: ->(e) { e.strip.downcase }
end
