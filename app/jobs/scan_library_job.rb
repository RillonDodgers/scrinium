class ScanLibraryJob < ApplicationJob
  queue_as :default

  def perform(library, scan_run)
    LibraryScanner.new(library:, scan_run:).call
  end
end
