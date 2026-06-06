class Admin::BooksController < Admin::BaseController
  before_action :set_library

  def index
    @books = @library.books.left_joins(:author, :series).includes(:author, :series, :book_files).order("authors.name", "series.name", :title)
  end

  def show
    @book = @library.books.includes(:author, :series, :book_files).find(params[:id])
  end

  private

  def set_library
    @library = Library.find(params[:library_id])
  end
end
