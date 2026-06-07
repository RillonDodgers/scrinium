require "hardcover/cover_importer"
require "hardcover/error"
require "set"

module Hardcover
  class MetadataApplicator
    FIELD_TITLE = "title"
    FIELD_AUTHOR = "author"
    FIELD_SERIES = "series"
    FIELD_EBOOK_COVER = "ebook_cover"
    FIELD_AUDIOBOOK_COVER = "audiobook_cover"

    def initialize(book:, metadata:, selected_fields:)
      @book = book
      @metadata = metadata
      @selected_fields = selected_fields.to_set
    end

    def call
      validate_cover_urls!

      ActiveRecord::Base.transaction do
        apply_metadata_fields
        apply_covers
      end
    end

  private

    attr_reader :book, :metadata, :selected_fields

    def apply_metadata_fields
      book.title = metadata.title if selected?(FIELD_TITLE) && metadata.title.present?
      book.author = author if selected?(FIELD_AUTHOR) && metadata.primary_author_name.present?
      book.series = series if selected?(FIELD_SERIES)
      book.save! if book.changed?
    end

    def apply_covers
      import_cover_for(:epub, metadata.ebook_cover_url) if selected?(FIELD_EBOOK_COVER)
      import_cover_for(:m4b, metadata.audiobook_cover_url) if selected?(FIELD_AUDIOBOOK_COVER)
    end

    def import_cover_for(format, url)
      book.book_files.where(format:).find_each do |book_file|
        CoverImporter.new(book_file:, url:).call
      end
    end

    def validate_cover_urls!
      raise Error, "Hardcover ebook cover URL is missing." if selected?(FIELD_EBOOK_COVER) && metadata.ebook_cover_url.blank? && book.book_files.epub.exists?
      raise Error, "Hardcover audiobook cover URL is missing." if selected?(FIELD_AUDIOBOOK_COVER) && metadata.audiobook_cover_url.blank? && book.book_files.m4b.exists?
    end

    def author
      @author ||= Author.find_or_create_by!(name: metadata.primary_author_name)
    end

    def series
      return if metadata.series_name.blank?

      Series.find_or_create_by!(author: book.author, name: metadata.series_name)
    end

    def selected?(field)
      selected_fields.include?(field)
    end
  end
end
