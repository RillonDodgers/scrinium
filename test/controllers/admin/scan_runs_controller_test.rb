require "test_helper"

class Admin::ScanRunsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @library = Library.create!(name: "Local", root_path: "/tmp/books")
  end

  test "admin can enqueue scan" do
    sign_in_as users(:admin)

    assert_enqueued_with(job: ScanLibraryJob) do
      post admin_library_scan_runs_path(@library)
    end

    assert_redirected_to admin_library_scan_run_path(@library, ScanRun.last)
  end

  test "admin can view scan run" do
    scan_run = @library.scan_runs.create!(status: :completed, found_count: 2, finished_at: Time.current)
    sign_in_as users(:admin)

    get admin_library_scan_run_path(@library, scan_run)

    assert_response :success
    assert_select "h1", "Scan run"
  end
end
