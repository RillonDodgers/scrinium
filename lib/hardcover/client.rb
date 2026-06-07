require "json"
require "net/http"
require "uri"

require "hardcover/book_metadata"
require "hardcover/error"

module Hardcover
  class Client
    ENDPOINT = URI("https://api.hardcover.app/v1/graphql")
    SEARCH_CACHE_TTL = 7.days

    SEARCH_QUERY = <<~GRAPHQL
      query SearchBooks($query: String!, $page: Int!, $perPage: Int!) {
        search(query: $query, query_type: "Book", page: $page, per_page: $perPage) {
          results
        }
      }
    GRAPHQL

    BOOK_METADATA_QUERY = <<~GRAPHQL
      query BookMetadata($id: Int!) {
        books(where: { id: { _eq: $id } }, limit: 1) {
          id
          title
          subtitle
          release_year
          rating
          contributions {
            author {
              name
            }
          }
          book_series {
            featured
            series {
              name
            }
          }
          default_cover_edition {
            cached_image
            image {
              url
            }
          }
          default_ebook_edition {
            cached_image
            image {
              url
            }
          }
          default_audio_edition {
            cached_image
            image {
              url
            }
          }
        }
      }
    GRAPHQL

    def initialize(token: ApplicationSetting.current.hardcover_api_token, endpoint: ENDPOINT, http: Net::HTTP)
      @token = token.to_s.strip
      @endpoint = endpoint
      @http = http
    end

    def search_books(query:, page: 1, per_page: 5)
      normalized_query = normalize_query(query)
      raise Error, "Enter a search query." if normalized_query.blank?

      Rails.cache.fetch(search_cache_key(normalized_query, page, per_page), expires_in: SEARCH_CACHE_TTL) do
        response = graphql(SEARCH_QUERY, query: normalized_query, page:, perPage: per_page)
        search_results_from(response)
      end
    end

    def book_metadata(id:)
      response = graphql(BOOK_METADATA_QUERY, id: id.to_i)
      book = Array(response.dig("data", "books")).first
      raise Error, "Hardcover book not found." if book.blank?

      BookMetadata.from_graphql(book)
    end

  private

    attr_reader :token, :endpoint, :http

    def graphql(query, variables = {})
      raise Error, "Hardcover API token is missing." if token.blank?

      request = Net::HTTP::Post.new(endpoint)
      request["authorization"] = token
      request["Content-Type"] = "application/json"
      request["User-Agent"] = "Scrinium Hardcover Metadata"
      request.body = JSON.generate(query:, variables:)

      response = http.start(endpoint.host, endpoint.port, use_ssl: endpoint.scheme == "https", read_timeout: 30) do |connection|
        connection.request(request)
      end

      parse_response(response)
    end

    def parse_response(response)
      body = JSON.parse(response.body)
      raise Error, "Hardcover API error: #{body["error"].presence || response.message}" unless response.is_a?(Net::HTTPSuccess)
      raise Error, "Hardcover API error: #{body.fetch("errors").pluck("message").to_sentence}" if body["errors"].present?

      body
    rescue JSON::ParserError
      raise Error, "Hardcover API returned invalid JSON."
    end

    def search_cache_key(query, page, per_page)
      [ "hardcover", "search_books", query, page.to_i, per_page.to_i ]
    end

    def search_results_from(response)
      results = response.dig("data", "search", "results")
      hits = results.is_a?(Hash) ? results["hits"] : results

      Array(hits).filter_map do |result|
        next result unless result.is_a?(Hash)

        result["document"].presence || result
      end
    end

    def normalize_query(query)
      query.to_s.squish.downcase
    end
  end
end
