require "test_helper"
require "tmpdir"

class BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @library = Library.create!(name: "Local", root_path: "/tmp/books")
    @author = Author.create!(name: "Matt Dinniman")
    @book = Book.create!(
      library: @library,
      author: @author,
      title: "Dungeon Crawler Carl",
      description: "A man. His ex-girlfriend's cat.",
      release_year: 2020,
      pages: 465,
      average_rating: 4.347,
      ratings_count: 2_554
    )
    @book.book_files.create!(format: :epub, relative_path: "Dungeon Crawler Carl.epub", status: :present, size_bytes: 5, mtime: Time.current)
    @book.book_files.create!(format: :m4b, relative_path: "Dungeon Crawler Carl.m4b", status: :missing, size_bytes: 5, mtime: Time.current)
    genre = MetadataTag.create!(hardcover_tag_id: 1, category: "Genre", category_slug: "genre", name: "Fantasy", slug: "fantasy")
    warning = MetadataTag.create!(hardcover_tag_id: 2, category: "Content Warning", category_slug: "content-warning", name: "Violence", slug: "violence")
    @book.book_metadata_tags.create!(metadata_tag: genre, count: 10, spoiler_ratio: 0)
    @book.book_metadata_tags.create!(metadata_tag: warning, count: 3, spoiler_ratio: 0)
  end

  test "user can view book detail with reading options and metadata" do
    sign_in_as users(:one)

    get book_path(@book)

    assert_response :success
    assert_select "h1", "Dungeon Crawler Carl"
    assert_select "div", text: /A man/
    assert_select "dd", "465"
    assert_select ".badge", "Fantasy"
    assert_select "summary", "Reveal"
    assert_select "h2", "Reading options"
    assert_select "a[href='#{read_book_path(@book)}']", "Open"
    assert_select "span.badge", "Unavailable"
  end

  test "user can open read page for present epub" do
    sign_in_as users(:one)

    get read_book_path(@book)

    assert_response :success
    assert_select "[data-controller='epub-reader']"
  end

  test "listen page redirects without present audiobook" do
    sign_in_as users(:one)

    get listen_book_path(@book)

    assert_redirected_to book_path(@book)
  end

  test "user can open listen and combined pages when both formats are present" do
    @book.book_files.find_by(format: :m4b).status_present!
    sign_in_as users(:one)

    get listen_book_path(@book)

    assert_response :success
    assert_select "[data-controller='audio-player']"

    get read_and_listen_book_path(@book)

    assert_response :success
    assert_select "[data-controller='epub-reader']"
    assert_select "[data-controller='audio-player']"
  end

  test "progress endpoint persists reading and listening state" do
    @book.book_files.find_by(format: :m4b).status_present!
    sign_in_as users(:one)

    patch progress_book_path(@book), params: {
      epub_location: "epubcfi(/6/2[test])",
      audio_position_seconds: "123.456",
      last_mode: "read_and_listen"
    }

    assert_response :no_content
    progress = @book.book_progresses.sole
    assert_equal "epubcfi(/6/2[test])", progress.epub_location
    assert_equal BigDecimal("123.456"), progress.audio_position_seconds
    assert_predicate progress, :last_mode_read_and_listen?
  end

  test "media endpoint streams full files and byte ranges" do
    Dir.mktmpdir do |root|
      @library.update!(root_path: root)
      File.write(File.join(root, "Dungeon Crawler Carl.epub"), "epub")
      m4b_path = File.join(root, "Dungeon Crawler Carl.m4b")
      File.binwrite(m4b_path, "0123456789")
      m4b_file = @book.book_files.find_by(format: :m4b)
      m4b_file.update!(status: :present, relative_path: "Dungeon Crawler Carl.m4b", size_bytes: 10)

      sign_in_as users(:one)

      get media_book_file_path(@book.book_files.find_by(format: :epub))
      assert_response :success
      assert_equal "application/epub+zip", response.media_type
      assert_equal "epub", response.body

      get media_book_file_path(m4b_file), headers: { "Range" => "bytes=2-5" }
      assert_response :partial_content
      assert_equal "bytes 2-5/10", response.headers["Content-Range"]
      assert_equal "2345", response.body

      get media_book_file_path(m4b_file), headers: { "Range" => "bytes=-3" }
      assert_response :partial_content
      assert_equal "bytes 7-9/10", response.headers["Content-Range"]
      assert_equal "789", response.body
    end
  end

  test "media endpoint denies missing files" do
    sign_in_as users(:one)

    get media_book_file_path(@book.book_files.find_by(format: :m4b))

    assert_response :not_found
  end

  test "read page requires authentication" do
    get read_book_path(@book)

    assert_redirected_to new_session_path
  end
end
