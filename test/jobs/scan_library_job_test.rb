require "test_helper"
require "tmpdir"

class ScanLibraryJobTest < ActiveJob::TestCase
  test "scans library and completes scan run" do
    Dir.mktmpdir do |root|
      path = File.join(root, "Andy Weir/Project Hail Mary/Project Hail Mary.m4b")
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, "media")

      library = Library.create!(name: "Local", root_path: root)
      scan_run = library.scan_runs.create!

      ScanLibraryJob.perform_now(library, scan_run)

      assert_predicate scan_run.reload, :completed?
      assert_equal 1, scan_run.found_count
      assert_equal 1, library.book_files.count
    end
  end
end
