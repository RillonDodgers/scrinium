require "test_helper"

class Admin::LibrariesControllerTest < ActionDispatch::IntegrationTest
  test "admin can view libraries" do
    sign_in_as users(:admin)

    get admin_libraries_path

    assert_response :success
  end

  test "admin can view library detail" do
    library = Library.create!(name: "Local", root_path: "/Users/dir/Documents/Books")
    sign_in_as users(:admin)

    get admin_library_path(library)

    assert_response :success
    assert_select "h1", "Local"
  end

  test "regular user cannot view libraries" do
    sign_in_as users(:one)

    get admin_libraries_path

    assert_redirected_to root_path
  end

  test "admin can create library" do
    sign_in_as users(:admin)

    assert_difference "Library.count", 1 do
      post admin_libraries_path, params: { library: { name: "Local", root_path: "/Users/dir/Documents/Books" } }
    end

    assert_redirected_to admin_library_path(Library.last)
  end

  test "admin can delete library records without deleting files" do
    root_path = Dir.mktmpdir
    file_path = File.join(root_path, "book.epub")
    File.write(file_path, "book")
    library = Library.create!(name: "Local", root_path:)
    author = Author.create!(name: "Author")
    book = Book.create!(library:, author:, title: "Book")
    book.book_files.create!(format: :epub, relative_path: "book.epub", size_bytes: 4, mtime: Time.current)
    library.scan_runs.create!(status: :completed)
    sign_in_as users(:admin)

    assert_difference "Library.count", -1 do
      assert_difference "Book.count", -1 do
        assert_difference "BookFile.count", -1 do
          assert_difference "ScanRun.count", -1 do
            delete admin_library_path(library)
          end
        end
      end
    end

    assert_redirected_to admin_libraries_path
    assert File.exist?(file_path)
  ensure
    FileUtils.rm_rf(root_path) if root_path
  end
end
