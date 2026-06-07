class HomeController < ApplicationController
  def index
    @query = params[:q].to_s.strip
    @media_filter = Current.user.library_media_filter
    @media_filter_options = [
      [ "Ebooks", "ebooks" ],
      [ "Audiobooks", "audiobooks" ],
      [ "Both", "both" ]
    ]

    @books = Book
      .joins(:book_files, :author)
      .merge(BookFile.status_present.where(format: selected_formats))
      .includes(:author, book_files: { cover_attachment: :blob })
      .distinct
      .order("books.title ASC")

    return if @query.blank?

    search = "%#{Book.sanitize_sql_like(@query.downcase)}%"
    @books = @books.where("LOWER(books.title) LIKE :search OR LOWER(authors.name) LIKE :search", search:)
  end

  private

  def selected_formats
    case @media_filter
    when "audiobooks"
      [ "m4b" ]
    when "both"
      [ "epub", "m4b" ]
    else
      [ "epub" ]
    end
  end
end
