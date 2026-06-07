class BooksController < ApplicationController
  def show
    @book = Book
      .includes(:author, :series, book_files: { cover_attachment: :blob }, book_metadata_tags: :metadata_tag)
      .find(params[:id])
  end
end
