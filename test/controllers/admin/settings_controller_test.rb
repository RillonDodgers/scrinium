require "test_helper"

class Admin::SettingsControllerTest < ActionDispatch::IntegrationTest
  test "admin can update hardcover api token" do
    sign_in_as users(:admin)

    patch admin_settings_path, params: { application_setting: { hardcover_api_token: "hc-token" } }

    assert_redirected_to edit_admin_settings_path
    assert_equal "hc-token", ApplicationSetting.current.hardcover_api_token
  end

  test "regular user cannot update settings" do
    sign_in_as users(:one)

    patch admin_settings_path, params: { application_setting: { hardcover_api_token: "hc-token" } }

    assert_redirected_to root_path
  end
end
