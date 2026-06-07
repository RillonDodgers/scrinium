require "test_helper"
require "hardcover/client"

class Hardcover::ClientTest < ActiveSupport::TestCase
  setup do
    ApplicationSetting.current.update!(hardcover_api_token: hardcover_api_token)
    @cache = ActiveSupport::Cache::MemoryStore.new
    @old_cache = Rails.cache
    Rails.instance_variable_set(:@cache, @cache)
  end

  teardown do
    Rails.instance_variable_set(:@cache, @old_cache)
  end

  test "search sends authorization header and caches normalized query" do
    requests = []
    response = json_response({ data: { search: { results: [ { id: 1, title: "Dune" } ] } } })

    http = fake_http(response, requests:)

    first = Hardcover::Client.new(http:).search_books(query: "  Dune  ")
    second = Hardcover::Client.new(http:).search_books(query: "dune")

    assert_equal [ { "id" => 1, "title" => "Dune" } ], first
    assert_equal first, second
    assert_equal 1, requests.length
    assert_equal hardcover_api_token, requests.first["authorization"]
    assert_match(/SearchBooks/, requests.first.body)
  end

  test "search unwraps Hardcover Typesense document hits" do
    response = json_response({
      data: {
        search: {
          results: {
            found: 5,
            hits: [
              {
                document: {
                  id: 427578,
                  title: "Project Hail Mary",
                  author_names: [ "Andy Weir" ],
                  series_names: []
                }
              }
            ]
          }
        }
      }
    })

    results = Hardcover::Client.new(http: fake_http(response)).search_books(query: "Project Hail Mary")

    assert_equal [ {
      "id" => 427578,
      "title" => "Project Hail Mary",
      "author_names" => [ "Andy Weir" ],
      "series_names" => []
    } ], results
  end

  test "search preserves flat result hashes" do
    response = json_response({
      data: {
        search: {
          results: [
            {
              id: 1,
              title: "Dune",
              author_names: [ "Frank Herbert" ]
            }
          ]
        }
      }
    })

    results = Hardcover::Client.new(http: fake_http(response)).search_books(query: "Dune")

    assert_equal [ {
      "id" => 1,
      "title" => "Dune",
      "author_names" => [ "Frank Herbert" ]
    } ], results
  end

  test "search replays GraphQL response from VCR cassette" do
    VCR.use_cassette("hardcover/search_books") do
      results = Hardcover::Client.new.search_books(query: "Project Hail Mary")

      assert_equal "Project Hail Mary", results.first.fetch("title")
      assert_equal [ "Andy Weir" ], results.first.fetch("author_names")
    end
  end

  test "book_metadata maps detail response" do
    response = json_response({
      data: {
        books: [
          {
            id: 7,
            title: "Dungeon Crawler Carl",
            subtitle: nil,
            release_year: 2020,
            rating: 4.5,
            contributions: [ { author: { name: "Matt Dinniman" } } ],
            book_series: [ { featured: true, series: { name: "Dungeon Crawler Carl" } } ],
            default_ebook_edition: { image: { url: "https://example.com/ebook.jpg" } },
            default_audio_edition: { image: { url: "https://example.com/audio.jpg" } }
          }
        ]
      }
    })

    metadata = Hardcover::Client.new(http: fake_http(response)).book_metadata(id: 7)

    assert_equal "Dungeon Crawler Carl", metadata.title
    assert_equal "Matt Dinniman", metadata.primary_author_name
    assert_equal "Dungeon Crawler Carl", metadata.series_name
    assert_equal "https://example.com/ebook.jpg", metadata.ebook_cover_url
    assert_equal "https://example.com/audio.jpg", metadata.audiobook_cover_url
  end

  test "raises on graphql errors" do
    response = json_response({ errors: [ { message: "Bad query" } ] })

    error = assert_raises(Hardcover::Error) { Hardcover::Client.new(http: fake_http(response)).search_books(query: "dune") }

    assert_equal "Hardcover API error: Bad query", error.message
  end

  test "raises on non success response" do
    response = json_response({ error: "Throttled" }, status: Net::HTTPTooManyRequests, code: "429", message: "Too Many Requests")

    error = assert_raises(Hardcover::Error) { Hardcover::Client.new(http: fake_http(response)).search_books(query: "dune") }

    assert_equal "Hardcover API error: Throttled", error.message
  end

  test "raises when token is missing" do
    ApplicationSetting.current.update!(hardcover_api_token: nil)

    error = assert_raises(Hardcover::Error) { Hardcover::Client.new.search_books(query: "dune") }

    assert_equal "Hardcover API token is missing.", error.message
  end

  test "search cache expires in seven days" do
    cache = Object.new
    expires_in = nil
    cache.define_singleton_method(:fetch) do |_key, options, &block|
      expires_in = options[:expires_in]
      block.call
    end
    Rails.instance_variable_set(:@cache, cache)
    response = json_response({ data: { search: { results: [] } } })

    Hardcover::Client.new(http: fake_http(response)).search_books(query: "dune")

    assert_equal 7.days, expires_in
  end

  test "search normalizes cached Hardcover result wrapper" do
    Rails.cache.write(
      [ "hardcover", "search_books", "v2", "project hail mary", 1, 5 ],
      {
        "found" => 5,
        "hits" => [
          {
            "document" => {
              "id" => 427578,
              "title" => "Project Hail Mary",
              "author_names" => [ "Andy Weir" ]
            }
          }
        ]
      }
    )

    results = Hardcover::Client.new.search_books(query: "Project Hail Mary")

    assert_equal [ {
      "id" => 427578,
      "title" => "Project Hail Mary",
      "author_names" => [ "Andy Weir" ]
    } ], results
  end

private

  def hardcover_api_token
    ENV.fetch("HARDCOVER_API_TOKEN", "hc-token")
  end

  def fake_http(response, requests: [])
    http = Object.new
    http.define_singleton_method(:start) do |_host, _port, **_options, &block|
      http = Object.new
      http.define_singleton_method(:request) do |request|
        requests << request
        response
      end
      block.call(http)
    end
    http
  end

  def json_response(body, status: Net::HTTPOK, code: "200", message: "OK")
    response = status.new("1.1", code, message)
    response.instance_variable_set(:@read, true)
    response.instance_variable_set(:@body, JSON.generate(body))
    response
  end
end
