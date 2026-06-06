class ScanRun < ApplicationRecord
  belongs_to :library

  enum :status, { pending: "pending", running: "running", completed: "completed", failed: "failed" }, validate: true

  scope :recent, -> { order(created_at: :desc) }

  def finish!
    update!(status: :completed, finished_at: Time.current)
  end

  def fail!(error)
    update!(status: :failed, finished_at: Time.current, error_count: error_count + 1, last_error: error.message)
  end
end
