module Hardcover
  TagMetadata = Data.define(
    :hardcover_tag_id,
    :category,
    :category_slug,
    :name,
    :slug,
    :count,
    :spoiler_ratio
  )

  BookMetadata = Data.define(
    :id,
    :slug,
    :title,
    :subtitle,
    :description,
    :author_names,
    :series_name,
    :series_id,
    :series_books_count,
    :series_position,
    :release_date,
    :release_year,
    :rating,
    :ratings_count,
    :ratings_distribution,
    :pages,
    :tags,
    :ebook_cover_url,
    :audiobook_cover_url
  ) do
    def self.from_graphql(book)
      ebook_edition = book["default_ebook_edition"] || book["default_cover_edition"] || {}
      audio_edition = book["default_audio_edition"] || {}

      new(
        id: book.fetch("id"),
        slug: book["slug"],
        title: book["title"],
        subtitle: book["subtitle"],
        description: book["description"],
        author_names: author_names_for(book),
        series_name: series_name_for(book),
        series_id: series_id_for(book),
        series_books_count: series_books_count_for(book),
        series_position: series_position_for(book),
        release_date: book["release_date"],
        release_year: book["release_year"],
        rating: book["rating"],
        ratings_count: book["ratings_count"],
        ratings_distribution: book["ratings_distribution"] || {},
        pages: book["pages"],
        tags: tags_for(book),
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

    def self.series_id_for(book)
      featured_series_for(book)&.dig("series", "id")
    end

    def self.series_books_count_for(book)
      featured_series_for(book)&.dig("series", "books_count")
    end

    def self.series_position_for(book)
      featured_series_for(book)&.dig("position")
    end

    def self.featured_series_for(book)
      featured = Array(book["book_series"]).find { |series| series["featured"] }
      featured || Array(book["book_series"]).first
    end

    def self.tags_for(book)
      Array(book["taggable_counts"]).filter_map do |tag_count|
        tag = tag_count["tag"]
        category = tag&.dig("tag_category")
        next if tag.blank? || category.blank?

        TagMetadata.new(
          hardcover_tag_id: tag["id"],
          category: category["category"],
          category_slug: category["slug"],
          name: tag["tag"],
          slug: tag["slug"],
          count: tag_count["count"].to_i,
          spoiler_ratio: BigDecimal(tag_count["spoiler_ratio"].presence || "0")
        )
      end
    end

    def self.image_url_for(edition)
      edition.dig("image", "url").presence || edition.dig("cached_image", "url").presence
    end
  end
end
