require "pathname"
require "set"

class LibraryScanner
  SUPPORTED_FORMATS = %w[ epub m4b ].freeze

  Result = Data.define(:found_count, :created_count, :updated_count, :missing_count, :error_count, :last_error)

  def initialize(library:, scan_run:)
    @library = library
    @scan_run = scan_run
    @found_paths = Set.new
    @created_count = 0
    @updated_count = 0
    @missing_count = 0
    @error_count = 0
    @last_error = nil
  end

  def call
    scan_run.update!(status: :running, started_at: Time.current)

    discover_files.each { |path| index_file(path) }
    mark_missing_files

    result = Result.new(found_paths.size, created_count, updated_count, missing_count, error_count, last_error)
    scan_run.update!(
      found_count: result.found_count,
      created_count: result.created_count,
      updated_count: result.updated_count,
      missing_count: result.missing_count,
      error_count: result.error_count,
      last_error: result.last_error
    )
    scan_run.finish!

    result
  rescue StandardError => error
    scan_run.fail!(error)
    raise
  end

  private

  attr_reader :library, :scan_run, :found_paths, :created_count, :updated_count, :missing_count, :error_count, :last_error

  def discover_files
    return [] unless Dir.exist?(library.root_path)

    Dir.glob(File.join(library.root_path, "**", "*"), File::FNM_CASEFOLD).select do |path|
      File.file?(path) && SUPPORTED_FORMATS.include?(File.extname(path).delete_prefix(".").downcase)
    end
  end

  def index_file(path)
    relative_path = Pathname.new(path).relative_path_from(Pathname.new(library.root_path)).to_s
    found_paths << relative_path

    metadata = metadata_for(relative_path)
    author = Author.find_or_create_by!(name: metadata.fetch(:author_name))
    series = find_or_create_series(author, metadata[:series_name])
    book = Book.find_or_create_by!(library:, author:, series:, title: metadata.fetch(:title))
    file_stat = File.stat(path)
    format = File.extname(path).delete_prefix(".").downcase
    book_file = book.book_files.find_or_initialize_by(format:, relative_path:)
    new_record = book_file.new_record?

    book_file.assign_attributes(status: :present, size_bytes: file_stat.size, mtime: file_stat.mtime)
    book_file.save! if new_record || book_file.changed?

    if new_record
      @created_count += 1
    elsif book_file.previous_changes.any?
      @updated_count += 1
    end
  rescue StandardError => error
    @error_count += 1
    @last_error = "#{relative_path || path}: #{error.message}"
  end

  def metadata_for(relative_path)
    segments = Pathname.new(relative_path).each_filename.to_a
    filename = segments.last
    author_name = clean_name(segments.first || "Unknown Author")

    if segments.length >= 4
      { author_name:, series_name: clean_name(segments.second), title: clean_name(segments[-2]) }
    elsif segments.length == 3
      { author_name:, series_name: nil, title: clean_name(segments[-2]) }
    else
      { author_name:, series_name: nil, title: clean_name(File.basename(filename, ".*")) }
    end
  end

  def clean_name(value)
    value.to_s.tr("_", " ").squish
  end

  def find_or_create_series(author, series_name)
    return if series_name.blank?

    Series.find_or_create_by!(author:, name: series_name)
  end

  def mark_missing_files
    library.book_files.where(status: :present).where.not(relative_path: found_paths.to_a).find_each do |book_file|
      book_file.status_missing!
      @missing_count += 1
    end
  end
end
