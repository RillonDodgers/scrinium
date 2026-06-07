require "open-uri"
require "securerandom"
require "uri"

require "hardcover/error"

module Hardcover
  class CoverImporter
    def initialize(book_file:, url:)
      @book_file = book_file
      @url = url.to_s
    end

    def call
      raise Error, "Hardcover cover URL is missing for #{book_file.format}." if url.blank?
      raise Error, "Hardcover cover URL must use HTTPS." unless URI(url).is_a?(URI::HTTPS)

      downloaded = URI.open(url, read_timeout: 30)
      book_file.cover.attach(
        io: downloaded,
        filename: filename_for(downloaded),
        content_type: downloaded.content_type.presence || "image/jpeg"
      )
    rescue URI::InvalidURIError, OpenURI::HTTPError, SocketError, IOError, SystemCallError => error
      raise Error, "Could not download Hardcover cover: #{error.message}"
    end

  private

    attr_reader :book_file, :url

    def filename_for(downloaded)
      extension = Rack::Mime::MIME_TYPES.invert[downloaded.content_type].presence || ".jpg"
      "hardcover-#{book_file.format}-#{SecureRandom.hex(8)}#{extension}"
    end
  end
end
