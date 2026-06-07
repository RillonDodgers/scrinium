class Admin::SettingsController < Admin::BaseController
  def edit
    @settings = ApplicationSetting.current
  end

  def update
    @settings = ApplicationSetting.current

    if @settings.update(settings_params)
      redirect_to edit_admin_settings_path, notice: "Settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

private

  def settings_params
    params.expect(application_setting: [ :hardcover_api_token ])
  end
end
