require "test_helper"
require "tmpdir"

class MediaProbeTest < ActiveSupport::TestCase
  setup do
    @library = Library.create!(name: "Local", root_path: Dir.mktmpdir)
    @author = Author.create!(name: "Matt Dinniman")
    @book = Book.create!(library: @library, author: @author, title: "Dungeon Crawler Carl")
  end

  teardown do
    FileUtils.remove_entry(@library.root_path) if @library&.root_path && Dir.exist?(@library.root_path)
  end

  test "probes m4b metadata with ffprobe" do
    File.write(File.join(@library.root_path, "book.m4b"), "audio")
    book_file = @book.book_files.create!(format: :m4b, relative_path: "book.m4b", size_bytes: 5, mtime: Time.current)
    payload = {
      format: { duration: "3605.25", bit_rate: "128000", tags: { title: "DCC" } },
      streams: [ { codec_type: "audio", codec_name: "aac", sample_rate: "44100", channels: 2 } ],
      chapters: [ { start_time: "0.0", end_time: "30.0", tags: { title: "Intro" } } ]
    }.to_json
    status = Object.new
    def status.success? = true

    original_capture3 = Open3.method(:capture3)
    Open3.define_singleton_method(:capture3) { |*_args| [ payload, "", status ] }

    begin
      attrs = MediaProbe.new(book_file:).call

      assert_equal 3605, attrs[:duration_seconds]
      assert_equal 128000, attrs[:bit_rate]
      assert_equal "aac", attrs[:codec]
      assert_equal 44100, attrs[:sample_rate]
      assert_equal 2, attrs[:channels]
      assert_equal "DCC", attrs[:media_metadata]["title"]
      assert_equal "Intro", attrs[:chapters].first["title"]
    ensure
      Open3.define_singleton_method(:capture3) { |*args| original_capture3.call(*args) }
    end
  end

  test "probes epub metadata from opf and ncx" do
    epub_path = File.join(@library.root_path, "book.epub")
    build_epub(epub_path)
    book_file = @book.book_files.create!(format: :epub, relative_path: "book.epub", size_bytes: File.size(epub_path), mtime: Time.current)

    attrs = MediaProbe.new(book_file:).call

    assert_equal "Test Book", attrs[:media_metadata]["title"]
    assert_equal "Test Author", attrs[:media_metadata]["creator"]
    assert_equal 1, attrs[:media_metadata]["spine_count"]
    assert_equal "Chapter 1", attrs[:chapters].first["title"]
  end

  private

  def build_epub(path)
    Dir.mktmpdir do |root|
      FileUtils.mkdir_p(File.join(root, "META-INF"))
      File.write(File.join(root, "META-INF/container.xml"), <<~XML)
        <container>
          <rootfiles>
            <rootfile full-path="content.opf"/>
          </rootfiles>
        </container>
      XML
      File.write(File.join(root, "content.opf"), <<~XML)
        <package xmlns="http://www.idpf.org/2007/opf">
          <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
            <dc:title>Test Book</dc:title>
            <dc:creator>Test Author</dc:creator>
            <dc:language>en</dc:language>
          </metadata>
          <manifest>
            <item id="chapter1" href="chapter1.xhtml" media-type="application/xhtml+xml"/>
            <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
          </manifest>
          <spine toc="ncx">
            <itemref idref="chapter1"/>
          </spine>
        </package>
      XML
      File.write(File.join(root, "toc.ncx"), <<~XML)
        <ncx>
          <navMap>
            <navPoint>
              <navLabel><text>Chapter 1</text></navLabel>
              <content src="chapter1.xhtml"/>
            </navPoint>
          </navMap>
        </ncx>
      XML
      File.write(File.join(root, "chapter1.xhtml"), "<html><body>Chapter</body></html>")
      system("zip", "-qr", path, ".", chdir: root)
    end
  end
end
