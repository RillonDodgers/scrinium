class ApplicationController < ActionController::Base
  include Authentication
  include ActionPolicy::Controller

  authorize :user, through: :current_user

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from ActionPolicy::Unauthorized, with: :deny_access

  private

  def current_user
    Current.user
  end

  def deny_access
    redirect_to root_path, alert: "You are not allowed to access that page."
  end
end
