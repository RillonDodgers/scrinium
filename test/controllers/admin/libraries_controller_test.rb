require "test_helper"

class Admin::LibrariesControllerTest < ActionDispatch::IntegrationTest
  test "admin can view libraries" do
    sign_in_as users(:admin)

    get admin_libraries_path

    assert_response :success
  end

  test "admin can view library detail" do
    library = Library.create!(name: "Local", root_path: "/Users/dir/Documents/Books")
    sign_in_as users(:admin)

    get admin_library_path(library)

    assert_response :success
    assert_select "h1", "Local"
  end

  test "regular user cannot view libraries" do
    sign_in_as users(:one)

    get admin_libraries_path

    assert_redirected_to root_path
  end

  test "admin can create library" do
    sign_in_as users(:admin)

    assert_difference "Library.count", 1 do
      post admin_libraries_path, params: { library: { name: "Local", root_path: "/Users/dir/Documents/Books" } }
    end

    assert_redirected_to admin_library_path(Library.last)
  end
end
