require "test_helper"

class BookFileTest < ActiveSupport::TestCase
  test "derives absolute path from library root and relative path" do
    library = Library.create!(name: "Local", root_path: "/tmp/books")
    author = Author.create!(name: "Andy Weir")
    book = Book.create!(library:, author:, title: "Project Hail Mary")
    book_file = BookFile.create!(
      book:,
      format: :m4b,
      relative_path: "Andy Weir/Project Hail Mary/Project Hail Mary.m4b",
      size_bytes: 12,
      mtime: Time.current
    )

    assert_equal "/tmp/books/Andy Weir/Project Hail Mary/Project Hail Mary.m4b", book_file.absolute_path
  end

  test "can attach a cover" do
    library = Library.create!(name: "Local", root_path: "/tmp/books")
    author = Author.create!(name: "Andy Weir")
    book = Book.create!(library:, author:, title: "Project Hail Mary")
    book_file = BookFile.create!(
      book:,
      format: :m4b,
      relative_path: "Andy Weir/Project Hail Mary/Project Hail Mary.m4b",
      size_bytes: 12,
      mtime: Time.current
    )

    book_file.cover.attach(io: StringIO.new("cover"), filename: "cover.jpg", content_type: "image/jpeg")

    assert_predicate book_file.cover, :attached?
  end
end
