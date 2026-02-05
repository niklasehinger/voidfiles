class ProfilesController < ApplicationController
  before_action :authenticate_user!

  def show
    @user = current_user
    @prproj_uploads = current_user.prproj_uploads.order(created_at: :desc).limit(10)
  end
end
