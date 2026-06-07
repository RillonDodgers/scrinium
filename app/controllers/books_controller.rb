class BooksController < ApplicationController
  before_action :set_book
  before_action :set_progress, only: %i[ read listen read_and_listen progress ]

  def show
  end

  def read
    @epub_file = @book.epub_file
    redirect_to @book, alert: "This book has no readable EPUB." unless @epub_file
  end

  def listen
    @m4b_file = @book.m4b_file
    redirect_to @book, alert: "This book has no audiobook." unless @m4b_file
  end

  def read_and_listen
    @epub_file = @book.epub_file
    @m4b_file = @book.m4b_file
    redirect_to @book, alert: "This book needs EPUB and M4B formats." unless @epub_file && @m4b_file
  end

  def progress
    @progress.assign_attributes(progress_attributes)
    @progress.save!

    head :no_content
  end

  private

  def set_book
    @book = Book
      .includes(:author, :series, :book_progresses, book_files: { cover_attachment: :blob }, book_metadata_tags: :metadata_tag)
      .find(params[:id])
  end

  def set_progress
    @progress = @book.progress_for(Current.user)
  end

  def progress_attributes
    {
      epub_book_file: @book.epub_file,
      m4b_book_file: @book.m4b_file,
      epub_location: params[:epub_location].presence || @progress.epub_location,
      audio_position_seconds: params.key?(:audio_position_seconds) ? params[:audio_position_seconds].to_d : @progress.audio_position_seconds,
      last_mode: params[:last_mode].presence || @progress.last_mode
    }
  end
end
