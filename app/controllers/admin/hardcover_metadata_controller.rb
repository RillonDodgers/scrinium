class Admin::HardcoverMetadataController < Admin::BaseController
  before_action :set_library
  before_action :set_book

  def search
    @hardcover_query = params[:query].presence || default_query
    @hardcover_results = hardcover_client.search_books(query: @hardcover_query)
    @hardcover_modal_open = true

    render "admin/books/show"
  rescue Hardcover::Error => error
    redirect_to admin_library_book_path(@library, @book), alert: error.message
  end

  def apply
    metadata = hardcover_client.book_metadata(id: params[:hardcover_book_id])
    Hardcover::MetadataApplicator.new(book: @book, metadata:, selected_fields: selected_fields).call

    redirect_to admin_library_book_path(@library, @book), notice: "Hardcover metadata applied."
  rescue Hardcover::Error => error
    redirect_to admin_library_book_path(@library, @book), alert: error.message
  end

private

  def set_library
    @library = Library.find(params[:library_id])
  end

  def set_book
    @book = @library.books.includes(:author, :series, :book_files).find(params[:book_id])
  end

  def hardcover_client
    Hardcover::Client.new
  end

  def selected_fields
    params.fetch(:fields, {}).keys
  end

  def default_query
    [ @book.title, @book.author.name ].join(" ")
  end
end
