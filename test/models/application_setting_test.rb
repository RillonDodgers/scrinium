require "test_helper"

class ApplicationSettingTest < ActiveSupport::TestCase
  test "current returns singleton settings record" do
    first = ApplicationSetting.current
    second = ApplicationSetting.current

    assert_equal first, second
  end

  test "encrypts hardcover api token" do
    settings = ApplicationSetting.current
    settings.update!(hardcover_api_token: "secret-token")

    assert_equal "secret-token", settings.reload.hardcover_api_token
    refute_includes ApplicationSetting.connection.select_value("select hardcover_api_token from application_settings where id = #{settings.id}"), "secret-token"
  end
end
