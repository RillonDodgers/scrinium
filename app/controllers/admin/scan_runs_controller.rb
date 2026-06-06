class Admin::ScanRunsController < Admin::BaseController
  before_action :set_library

  def create
    scan_run = @library.scan_runs.create!
    ScanLibraryJob.perform_later(@library, scan_run)

    redirect_to admin_library_scan_run_path(@library, scan_run), notice: "Scan started."
  end

  def show
    @scan_run = @library.scan_runs.find(params[:id])
  end

  private

  def set_library
    @library = Library.find(params[:library_id])
  end
end
