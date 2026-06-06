require "test_helper"

class Admin::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @library = Library.create!(name: "Local", root_path: "/tmp/books")
    @author = Author.create!(name: "Matt Dinniman")
    @book = Book.create!(library: @library, author: @author, title: "Dungeon Crawler Carl")
    @book.book_files.create!(format: :epub, relative_path: "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.epub", status: :present, size_bytes: 5, mtime: Time.current)
  end

  test "admin can view books" do
    sign_in_as users(:admin)

    get admin_library_books_path(@library)

    assert_response :success
    assert_select "td", "Dungeon Crawler Carl"
  end

  test "admin can view book detail" do
    sign_in_as users(:admin)

    get admin_library_book_path(@library, @book)

    assert_response :success
    assert_select "h1", "Dungeon Crawler Carl"
    assert_select "code", "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.epub"
  end

  test "regular user cannot view books" do
    sign_in_as users(:one)

    get admin_library_books_path(@library)

    assert_redirected_to root_path
  end
end
