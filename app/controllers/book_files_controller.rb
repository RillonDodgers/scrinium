class BookFilesController < ApplicationController
  def media
    book_file = BookFile.status_present.find(params[:id])
    path = book_file.absolute_path

    return head :not_found unless File.file?(path)

    if request.headers["Range"].present?
      send_range(book_file, path)
    else
      send_file path, type: content_type_for(book_file), disposition: "inline"
    end
  end

  private

  def send_range(book_file, path)
    file_size = File.size(path)
    start_byte, end_byte = requested_range(file_size)
    length = end_byte - start_byte + 1

    response.headers["Accept-Ranges"] = "bytes"
    response.headers["Content-Range"] = "bytes #{start_byte}-#{end_byte}/#{file_size}"
    response.headers["Content-Length"] = length.to_s

    send_data File.binread(path, length, start_byte),
      status: :partial_content,
      type: content_type_for(book_file),
      disposition: "inline"
  rescue ArgumentError
    head :range_not_satisfiable
  end

  def requested_range(file_size)
    match = request.headers["Range"].to_s.match(/\Abytes=(\d*)-(\d*)\z/)
    raise ArgumentError unless match

    if match[1].blank?
      suffix_length = match[2].to_i
      raise ArgumentError unless suffix_length.positive?

      start_byte = [ file_size - suffix_length, 0 ].max
      end_byte = file_size - 1
    else
      start_byte = match[1].to_i
      end_byte = match[2].present? ? match[2].to_i : file_size - 1
    end
    end_byte = [ end_byte, file_size - 1 ].min

    raise ArgumentError if start_byte.negative? || end_byte < start_byte || start_byte >= file_size

    [ start_byte, end_byte ]
  end

  def content_type_for(book_file)
    if book_file.epub?
      "application/epub+zip"
    else
      "audio/mp4"
    end
  end
end
