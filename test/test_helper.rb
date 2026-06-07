ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "vcr"
require "webmock/minitest"
require_relative "test_helpers/session_test_helper"

def load_test_env_file
  env_path = Rails.root.join(".env")
  return unless env_path.file?

  env_path.each_line do |line|
    line = line.strip
    next if line.blank? || line.start_with?("#")

    key, value = line.split("=", 2)
    next if key.blank? || value.nil?

    ENV[key] ||= value.delete_prefix('"').delete_suffix('"').delete_prefix("'").delete_suffix("'")
  end
end

load_test_env_file

VCR.configure do |config|
  config.cassette_library_dir = Rails.root.join("test/vcr_cassettes")
  config.hook_into :webmock
  config.filter_sensitive_data("<HARDCOVER_API_TOKEN>") { ENV["HARDCOVER_API_TOKEN"] }
  config.default_cassette_options = { match_requests_on: %i[ method uri body ] }
  config.allow_http_connections_when_no_cassette = false
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...
  end
end
