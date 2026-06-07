require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  setup do
    @library = Library.create!(name: "Local", root_path: "/tmp/books")
    @author = Author.create!(name: "Matt Dinniman")
    @book = Book.create!(library: @library, author: @author, title: "Dungeon Crawler Carl")
    @ebook_file = @book.book_files.create!(
      format: :epub,
      relative_path: "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.epub",
      status: :present,
      size_bytes: 5,
      mtime: Time.current
    )
  end

  test "user sees ebook shelf" do
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select "h1", "Library"
    assert_select "h3", "Dungeon Crawler Carl"
    assert_select "p", "Matt Dinniman"
  end

  test "user defaults to saved media filter" do
    @book.book_files.create!(
      format: :m4b,
      relative_path: "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.m4b",
      status: :present,
      size_bytes: 5,
      mtime: Time.current
    )
    users(:one).update!(library_media_filter: :audiobooks)
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select ".badge", "m4b"
    assert_select ".badge", text: "epub", count: 0
  end

  test "both media filter shows ebooks and audiobooks" do
    @book.book_files.create!(
      format: :m4b,
      relative_path: "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.m4b",
      status: :present,
      size_bytes: 5,
      mtime: Time.current
    )
    users(:one).update!(library_media_filter: :both)
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select ".badge", "epub"
    assert_select ".badge", "m4b"
  end

  test "user sees attached ebook cover" do
    @ebook_file.cover.attach(io: StringIO.new("cover"), filename: "cover.jpg", content_type: "image/jpeg")
    sign_in_as users(:one)

    get root_path

    assert_response :success
    assert_select "img[alt='Dungeon Crawler Carl cover']"
  end

  test "user can search ebooks by title" do
    other_book = Book.create!(library: @library, author: @author, title: "The Eye of the Bedlam Bride")
    other_book.book_files.create!(
      format: :epub,
      relative_path: "Matt Dinniman/Dungeon Crawler Carl/The Eye of the Bedlam Bride.epub",
      status: :present,
      size_bytes: 5,
      mtime: Time.current
    )
    sign_in_as users(:one)

    get root_path, params: { q: "bedlam" }

    assert_response :success
    assert_select "h3", "The Eye of the Bedlam Bride"
    assert_select "h3", text: "Dungeon Crawler Carl", count: 0
  end
end
