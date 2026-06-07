class LibraryMediaFiltersController < ApplicationController
  def update
    if media_filter.in?(User.library_media_filters.keys)
      Current.user.update!(library_media_filter: media_filter)
    end

    redirect_to root_path(q: params[:q].presence)
  end

  private

  def media_filter
    params[:media_filter].to_s
  end
end
