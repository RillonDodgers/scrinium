require "hardcover/cover_importer"
require "hardcover/error"
require "set"

module Hardcover
  class MetadataApplicator
    FIELD_TITLE = "title"
    FIELD_AUTHOR = "author"
    FIELD_SERIES = "series"
    FIELD_DETAILS = "details"
    FIELD_TAGS = "tags"
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
        apply_tags
        apply_covers
      end
    end

  private

    attr_reader :book, :metadata, :selected_fields

    def apply_metadata_fields
      book.title = metadata.title if selected?(FIELD_TITLE) && metadata.title.present?
      book.author = author if selected?(FIELD_AUTHOR) && metadata.primary_author_name.present?
      book.series = series if selected?(FIELD_SERIES)
      apply_details if selected?(FIELD_DETAILS)
      book.save! if book.changed?
    end

    def apply_details
      book.hardcover_id = metadata.id
      book.hardcover_slug = metadata.slug
      book.subtitle = metadata.subtitle
      book.description = metadata.description
      book.release_date = metadata.release_date
      book.release_year = metadata.release_year
      book.pages = metadata.pages
      book.average_rating = metadata.rating
      book.ratings_count = metadata.ratings_count
      book.ratings_distribution = metadata.ratings_distribution
      book.series_position = metadata.series_position
    end

    def apply_tags
      return unless selected?(FIELD_TAGS)

      applied_tag_ids = metadata.tags.map do |tag_metadata|
        metadata_tag = find_or_initialize_metadata_tag(tag_metadata)
        metadata_tag.update!(
          hardcover_tag_id: tag_metadata.hardcover_tag_id,
          category: tag_metadata.category,
          category_slug: tag_metadata.category_slug,
          name: tag_metadata.name,
          slug: tag_metadata.slug
        )

        book_metadata_tag = book.book_metadata_tags.find_or_initialize_by(metadata_tag:)
        book_metadata_tag.update!(count: tag_metadata.count, spoiler_ratio: tag_metadata.spoiler_ratio)
        metadata_tag.id
      end

      book.book_metadata_tags.where.not(metadata_tag_id: applied_tag_ids).destroy_all
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

      Series.find_or_initialize_by(author: book.author, name: metadata.series_name).tap do |series|
        series.hardcover_id = metadata.series_id
        series.books_count = metadata.series_books_count
        series.save!
      end
    end

    def find_or_initialize_metadata_tag(tag_metadata)
      if tag_metadata.hardcover_tag_id.present?
        MetadataTag.find_or_initialize_by(hardcover_tag_id: tag_metadata.hardcover_tag_id)
      else
        MetadataTag.find_or_initialize_by(category_slug: tag_metadata.category_slug, slug: tag_metadata.slug)
      end
    end

    def selected?(field)
      selected_fields.include?(field)
    end
  end
end
