require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "downcases and strips email" do
    user = User.new(email: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", user.email)
  end

  test "defaults role to user" do
    assert_predicate User.new, :user?
  end

  test "defaults library media filter to ebooks" do
    assert_predicate User.new, :library_media_filter_ebooks?
  end
end
