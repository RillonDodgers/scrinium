class Admin::LibrariesController < Admin::BaseController
  before_action :set_library, only: %i[ show edit update ]

  def index
    @libraries = Library.order(:name)
  end

  def show
    @scan_runs = @library.scan_runs.recent.limit(5)
    @books = @library.books.left_joins(:author, :series).includes(:author, :series, :book_files).order("authors.name", "series.name", :title).limit(10)
  end

  def new
    @library = Library.new(root_path: "/Users/dir/Documents/Books")
  end

  def edit
  end

  def create
    @library = Library.new(library_params)

    if @library.save
      redirect_to admin_library_path(@library), notice: "Library created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @library.update(library_params)
      redirect_to admin_library_path(@library), notice: "Library updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_library
    @library = Library.find(params[:id])
  end

  def library_params
    params.expect(library: %i[ name root_path ])
  end
end
