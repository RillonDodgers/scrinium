module Hardcover
  BookMetadata = Data.define(
    :id,
    :title,
    :subtitle,
    :author_names,
    :series_name,
    :release_year,
    :rating,
    :ebook_cover_url,
    :audiobook_cover_url
  ) do
    def self.from_graphql(book)
      ebook_edition = book["default_ebook_edition"] || book["default_cover_edition"] || {}
      audio_edition = book["default_audio_edition"] || {}

      new(
        id: book.fetch("id"),
        title: book["title"],
        subtitle: book["subtitle"],
        author_names: author_names_for(book),
        series_name: series_name_for(book),
        release_year: book["release_year"],
        rating: book["rating"],
        ebook_cover_url: image_url_for(ebook_edition),
        audiobook_cover_url: image_url_for(audio_edition)
      )
    end

    def primary_author_name
      author_names.first
    end

    def self.author_names_for(book)
      Array(book["contributions"]).filter_map do |contribution|
        contribution.dig("author", "name")
      end.uniq
    end

    def self.series_name_for(book)
      featured = Array(book["book_series"]).find { |series| series["featured"] }
      featured ||= Array(book["book_series"]).first
      featured&.dig("series", "name")
    end

    def self.image_url_for(edition)
      edition.dig("image", "url").presence || edition.dig("cached_image", "url").presence
    end
  end
end
