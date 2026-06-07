require "test_helper"

class Admin::BooksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @library = Library.create!(name: "Local", root_path: "/tmp/books")
    @author = Author.create!(name: "Matt Dinniman")
    @book = Book.create!(library: @library, author: @author, title: "Dungeon Crawler Carl")
    @book.book_files.create!(format: :epub, relative_path: "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.epub", status: :present, size_bytes: 5, mtime: Time.current)
    @book.book_files.create!(format: :m4b, relative_path: "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.m4b", status: :present, size_bytes: 5, mtime: Time.current)
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
    assert_select "span", { text: "No cover", count: 2 }
    assert_select "code", "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.epub"
  end

  test "regular user cannot view books" do
    sign_in_as users(:one)

    get admin_library_books_path(@library)

    assert_redirected_to root_path
  end

  test "admin can search hardcover metadata" do
    sign_in_as users(:admin)

    with_singleton_method(Hardcover::Client, :new, fake_client(search_results: [ { "id" => 123, "title" => "Dungeon Crawler Carl", "author_names" => [ "Matt Dinniman" ] } ])) do
      get admin_library_book_hardcover_search_path(@library, @book), params: { query: "Dungeon Crawler Carl" }
    end

    assert_response :success
    assert_select "dialog[open]"
    assert_select "h3", "Dungeon Crawler Carl"
  end

  test "regular user cannot search hardcover metadata" do
    sign_in_as users(:one)

    get admin_library_book_hardcover_search_path(@library, @book), params: { query: "Dungeon Crawler Carl" }

    assert_redirected_to root_path
  end

  test "apply updates selected fields only" do
    sign_in_as users(:admin)
    metadata = Hardcover::BookMetadata.new(
      id: 123,
      title: "Dungeon Crawler Carl Updated",
      subtitle: nil,
      author_names: [ "Matt Dinniman Updated" ],
      series_name: "Dungeon Crawler Carl",
      release_year: 2020,
      rating: 4.5,
      ebook_cover_url: nil,
      audiobook_cover_url: nil
    )

    with_singleton_method(Hardcover::Client, :new, fake_client(metadata:)) do
      post admin_library_book_hardcover_metadata_path(@library, @book), params: {
        hardcover_book_id: 123,
        fields: { title: "1" }
      }
    end

    assert_redirected_to admin_library_book_path(@library, @book)
    assert_equal "Dungeon Crawler Carl Updated", @book.reload.title
    assert_equal "Matt Dinniman", @book.author.name
    assert_nil @book.series
  end

  test "apply attaches epub and audiobook covers independently" do
    sign_in_as users(:admin)
    metadata = Hardcover::BookMetadata.new(
      id: 123,
      title: "Dungeon Crawler Carl",
      subtitle: nil,
      author_names: [ "Matt Dinniman" ],
      series_name: nil,
      release_year: 2020,
      rating: 4.5,
      ebook_cover_url: "https://example.com/ebook.jpg",
      audiobook_cover_url: "https://example.com/audio.jpg"
    )

    importer_factory = method(:fake_cover_importer)
    with_singleton_method(Hardcover::Client, :new, fake_client(metadata:)) do
      with_singleton_method(Hardcover::CoverImporter, :new, ->(book_file:, url:) { importer_factory.call(book_file:, url:) }) do
        post admin_library_book_hardcover_metadata_path(@library, @book), params: {
          hardcover_book_id: 123,
          fields: { ebook_cover: "1", audiobook_cover: "1" }
        }
      end
    end

    assert_redirected_to admin_library_book_path(@library, @book)
    assert_predicate @book.book_files.find_by(format: :epub).cover, :attached?
    assert_predicate @book.book_files.find_by(format: :m4b).cover, :attached?
  end

  test "missing token error redirects without partial update" do
    sign_in_as users(:admin)

    with_singleton_method(Hardcover::Client, :new, fake_client(error: Hardcover::Error.new("Hardcover API token is missing."))) do
      post admin_library_book_hardcover_metadata_path(@library, @book), params: {
        hardcover_book_id: 123,
        fields: { title: "1" }
      }
    end

    assert_redirected_to admin_library_book_path(@library, @book)
    assert_equal "Hardcover API token is missing.", flash[:alert]
    assert_equal "Dungeon Crawler Carl", @book.reload.title
  end

  private

  def fake_client(search_results: [], metadata: nil, error: nil)
    client = Object.new
    client.define_singleton_method(:search_books) do |**|
      raise error if error

      search_results
    end
    client.define_singleton_method(:book_metadata) do |**|
      raise error if error

      metadata
    end
    -> { client }
  end

  def fake_cover_importer(book_file:, url:)
    importer = Object.new
    importer.define_singleton_method(:call) do
      book_file.cover.attach(io: StringIO.new(url), filename: "#{book_file.format}.jpg", content_type: "image/jpeg")
    end
    importer
  end

  def with_singleton_method(object, method_name, replacement)
    original = object.method(method_name)
    object.define_singleton_method(method_name, &replacement)
    yield
  ensure
    object.define_singleton_method(method_name) do |*args, **kwargs, &block|
      original.call(*args, **kwargs, &block)
    end
  end
end
