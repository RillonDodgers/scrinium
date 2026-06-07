require "json"
require "nokogiri"
require "open3"

class MediaProbe
  def initialize(book_file:)
    @book_file = book_file
  end

  def call
    return {} unless File.exist?(book_file.absolute_path)

    if book_file.m4b?
      probe_m4b
    elsif book_file.epub?
      probe_epub
    else
      {}
    end
  rescue StandardError
    {}
  end

  private

  attr_reader :book_file

  def probe_m4b
    stdout, _stderr, status = Open3.capture3(
      "ffprobe",
      "-v", "error",
      "-print_format", "json",
      "-show_format",
      "-show_streams",
      "-show_chapters",
      book_file.absolute_path
    )
    return {} unless status.success?

    data = JSON.parse(stdout)
    audio_stream = data.fetch("streams", []).find { |stream| stream["codec_type"] == "audio" } || {}
    format = data.fetch("format", {})

    {
      duration_seconds: seconds(format["duration"] || audio_stream["duration"]),
      bit_rate: integer(format["bit_rate"] || audio_stream["bit_rate"]),
      codec: audio_stream["codec_name"],
      sample_rate: integer(audio_stream["sample_rate"]),
      channels: integer(audio_stream["channels"]),
      media_metadata: format.fetch("tags", {}).compact,
      chapters: chapters_from(data.fetch("chapters", []))
    }.compact
  end

  def probe_epub
    opf_path = opf_path_for_epub
    opf = read_epub_entry(opf_path)
    return {} if opf.blank?

    opf_doc = Nokogiri::XML(opf)
    opf_doc.remove_namespaces!
    ncx_path = ncx_path_for(opf_doc, opf_path)
    ncx = read_epub_entry(ncx_path)

    {
      media_metadata: {
        "title" => opf_doc.at_xpath("//metadata/title")&.text,
        "creator" => opf_doc.at_xpath("//metadata/creator")&.text,
        "language" => opf_doc.at_xpath("//metadata/language")&.text,
        "spine_count" => opf_doc.xpath("//spine/itemref").size
      }.compact,
      chapters: epub_chapters_from(ncx)
    }
  end

  def opf_path_for_epub
    container = read_epub_entry("META-INF/container.xml")
    return "content.opf" if container.blank?

    doc = Nokogiri::XML(container)
    doc.remove_namespaces!
    doc.at_xpath("//rootfile")&.[]("full-path").presence || "content.opf"
  end

  def ncx_path_for(opf_doc, opf_path)
    ncx_item = opf_doc.at_xpath("//manifest/item[@media-type='application/x-dtbncx+xml']")
    ncx_href = ncx_item&.[]("href")
    return "toc.ncx" if ncx_href.blank?

    File.join(File.dirname(opf_path), ncx_href).delete_prefix("./")
  end

  def read_epub_entry(entry)
    stdout, _stderr, status = Open3.capture3("unzip", "-p", book_file.absolute_path, entry)
    return unless status.success?

    stdout
  end

  def chapters_from(raw_chapters)
    raw_chapters.map do |chapter|
      {
        "title" => chapter.dig("tags", "title").presence || "Chapter #{chapter["id"]}",
        "start_time" => chapter["start_time"].to_f,
        "end_time" => chapter["end_time"].to_f
      }
    end
  end

  def epub_chapters_from(ncx)
    return [] if ncx.blank?

    doc = Nokogiri::XML(ncx)
    doc.remove_namespaces!
    doc.xpath("//navPoint").map do |nav_point|
      {
        "title" => nav_point.at_xpath(".//navLabel/text")&.text,
        "href" => nav_point.at_xpath(".//content")&.[]("src")
      }.compact
    end
  end

  def seconds(value)
    value.to_f.round if value.present?
  end

  def integer(value)
    value.to_i if value.present?
  end
end
