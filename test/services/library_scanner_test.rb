require "test_helper"
require "tmpdir"

class LibraryScannerTest < ActiveSupport::TestCase
  test "indexes supported files and groups paired media under one book" do
    with_library_root do |root|
      write_file(root, "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.epub")
      write_file(root, "Matt Dinniman/Dungeon Crawler Carl/Dungeon Crawler Carl.m4b")
      write_file(root, "Matt Dinniman/Dungeon Crawler Carl/cover.jpg")

      library = Library.create!(name: "Local", root_path: root)
      scan_run = library.scan_runs.create!

      result = LibraryScanner.new(library:, scan_run:).call

      assert_equal 2, result.found_count
      assert_equal 2, result.created_count
      assert_equal 0, result.error_count
      assert_predicate scan_run.reload, :completed?

      book = library.books.sole
      assert_equal "Dungeon Crawler Carl", book.title
      assert_equal "Matt Dinniman", book.author.name
      assert_nil book.series
      assert_equal %w[ epub m4b ], book.book_files.order(:format).pluck(:format)
    end
  end

  test "infers author series and title from nested path" do
    with_library_root do |root|
      write_file(root, "Brandon Sanderson/Mistborn/The Final Empire/The Final Empire.m4b")

      library = Library.create!(name: "Local", root_path: root)
      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call

      book = library.books.sole
      assert_equal "Brandon Sanderson", book.author.name
      assert_equal "Mistborn", book.series.name
      assert_equal "The Final Empire", book.title
    end
  end

  test "marks missing files on rescan" do
    with_library_root do |root|
      path = write_file(root, "Matt Dinniman/Carl's Doomsday Scenario/Carl's Doomsday Scenario.epub")
      library = Library.create!(name: "Local", root_path: root)

      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call
      File.delete(path)
      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call

      assert_predicate library.book_files.sole, :status_missing?
      assert_equal 1, library.scan_runs.order(:created_at).last.missing_count
    end
  end

  test "reconciles moved files into inferred series instead of creating duplicates" do
    with_library_root do |root|
      old_path = write_file(root, "Matt Dinniman/Carl's Doomsday Scenario/Carl's Doomsday Scenario.epub")
      library = Library.create!(name: "Local", root_path: root)

      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call

      new_path = File.join(root, "Matt Dinniman/Dungeon Crawler Carl/Carl's Doomsday Scenario/Carl's Doomsday Scenario.epub")
      FileUtils.mkdir_p(File.dirname(new_path))
      FileUtils.mv(old_path, new_path)

      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call

      assert_equal 1, library.books.count
      assert_equal 1, library.book_files.count

      book = library.books.sole
      assert_equal "Dungeon Crawler Carl", book.series.name
      assert_equal "Matt Dinniman/Dungeon Crawler Carl/Carl's Doomsday Scenario/Carl's Doomsday Scenario.epub", book.book_files.sole.relative_path
      assert_predicate book.book_files.sole, :status_present?
    end
  end

  test "cleans duplicate missing records after moved file was already indexed" do
    with_library_root do |root|
      write_file(root, "Matt Dinniman/Dungeon Crawler Carl/Carl's Doomsday Scenario/Carl's Doomsday Scenario.epub")
      library = Library.create!(name: "Local", root_path: root)
      author = Author.create!(name: "Matt Dinniman")
      old_book = Book.create!(library:, author:, title: "Carl's Doomsday Scenario")
      old_book.book_files.create!(
        format: :epub,
        relative_path: "Matt Dinniman/Carl's Doomsday Scenario/Carl's Doomsday Scenario.epub",
        status: :missing,
        size_bytes: 5,
        mtime: Time.current
      )

      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call

      assert_equal 1, library.books.count
      assert_equal 1, library.book_files.count
      assert_equal "Dungeon Crawler Carl", library.books.sole.series.name
      assert_equal 0, library.book_files.status_missing.count
    end
  end

  test "uses filename as title for author level files" do
    with_library_root do |root|
      write_file(root, "Andy Weir/Project Hail Mary.m4b")
      library = Library.create!(name: "Local", root_path: root)

      LibraryScanner.new(library:, scan_run: library.scan_runs.create!).call

      book = library.books.sole
      assert_equal "Andy Weir", book.author.name
      assert_equal "Project Hail Mary", book.title
    end
  end

  private

  def with_library_root
    Dir.mktmpdir { |root| yield root }
  end

  def write_file(root, relative_path)
    path = File.join(root, relative_path)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, "media")
    path
  end
end
