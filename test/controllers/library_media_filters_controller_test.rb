require "test_helper"

class LibraryMediaFiltersControllerTest < ActionDispatch::IntegrationTest
  test "user saves library media filter" do
    sign_in_as users(:one)

    patch library_media_filter_path, params: { media_filter: "both" }

    assert_redirected_to root_path
    assert_predicate users(:one).reload, :library_media_filter_both?
  end

  test "invalid filter does not update preference" do
    sign_in_as users(:one)

    patch library_media_filter_path, params: { media_filter: "invalid" }

    assert_redirected_to root_path
    assert_predicate users(:one).reload, :library_media_filter_ebooks?
  end
end
