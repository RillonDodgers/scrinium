class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  enum :role, { admin: "admin", user: "user" }, default: :user

  normalizes :email, with: ->(e) { e.strip.downcase }
end
