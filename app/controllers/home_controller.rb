class HomeController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @ebook_files = BookFile
      .epub
      .status_present
      .joins(book: :author)
      .includes(:cover_attachment, book: [ :author, :library ])
      .order("books.title ASC")

    return if @query.blank?

    search = "%#{Book.sanitize_sql_like(@query.downcase)}%"
    @ebook_files = @ebook_files.where("LOWER(books.title) LIKE :search OR LOWER(authors.name) LIKE :search", search:)
  end
end
