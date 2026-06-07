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
    file_stat = File.stat(path)
    format = File.extname(path).delete_prefix(".").downcase
    book_file = find_existing_file(author:, series:, title: metadata.fetch(:title), format:, relative_path:)
    book = book_file&.book || Book.find_or_create_by!(library:, author:, series:, title: metadata.fetch(:title))

    if book_file&.book && (book_file.book.series != series || book_file.book.author != author)
      book_file.book.update!(author:, series:)
    end

    book_file ||= book.book_files.find_or_initialize_by(format:, relative_path:)
    new_record = book_file.new_record?

    book_file.assign_attributes(relative_path:, status: :present, size_bytes: file_stat.size, mtime: file_stat.mtime)
    assign_media_probe(book_file) if should_probe_media?(book_file, new_record)
    book_file.save! if new_record || book_file.changed?

    if new_record
      @created_count += 1
    elsif book_file.previous_changes.any?
      @updated_count += 1
    end

    cleanup_missing_duplicates(author:, title: metadata.fetch(:title), format:, current_file: book_file)
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

  def find_existing_file(author:, series:, title:, format:, relative_path:)
    book = Book.find_by(library:, author:, series:, title:)
    file = book&.book_files&.find_by(format:, relative_path:)
    return file if file

    missing_book = Book.joins(:book_files).find_by(
      library:,
      author:,
      title:,
      book_files: { format:, status: :missing }
    )
    return missing_book.book_files.where(format:, status: :missing).first if missing_book

    Book.joins(:book_files).where(library:, author:, title:, book_files: { format:, status: :present }).find_each do |candidate_book|
      stale_file = candidate_book.book_files.where(format:, status: :present).detect do |book_file|
        !File.exist?(book_file.absolute_path)
      end
      return stale_file if stale_file
    end

    nil
  end

  def cleanup_missing_duplicates(author:, title:, format:, current_file:)
    Book.joins(:book_files).where(library:, author:, title:, book_files: { format:, status: :missing }).find_each do |book|
      book.book_files.where(format:, status: :missing).where.not(id: current_file.id).destroy_all
      book.destroy! if book.book_files.reload.none?
    end
  end

  def should_probe_media?(book_file, new_record)
    new_record || book_file.changed? || (book_file.media_metadata.blank? && book_file.chapters.blank?)
  end

  def assign_media_probe(book_file)
    book_file.assign_attributes(MediaProbe.new(book_file:).call)
  end

  def mark_missing_files
    library.book_files.where(status: :present).where.not(relative_path: found_paths.to_a).find_each do |book_file|
      book_file.status_missing!
      @missing_count += 1
    end
  end
end
