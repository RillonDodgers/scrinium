require "test_helper"

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

  test "user can view book detail with media options and metadata" do
    sign_in_as users(:one)

    get book_path(@book)

    assert_response :success
    assert_select "h1", "Dungeon Crawler Carl"
    assert_select "div", text: /A man/
    assert_select "dd", "465"
    assert_select ".badge", "Fantasy"
    assert_select "summary", "Reveal"
    assert_select ".badge", "present"
    assert_select ".badge", "missing"
  end
end
