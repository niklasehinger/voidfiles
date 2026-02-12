class AdminController < ApplicationController
  before_action :authenticate_user!
  before_action :check_admin

  def index
    @users = User.includes(:prproj_uploads).order(created_at: :desc)
  end

  def destroy
    @user = User.find(params[:id])
    if @user == current_user
      redirect_to admin_path(locale: I18n.locale), alert: I18n.t('admin.cannot_delete_self')
    elsif @user.destroy
      redirect_to admin_path(locale: I18n.locale), notice: I18n.t('admin.user_deleted')
    else
      redirect_to admin_path(locale: I18n.locale), alert: I18n.t('admin.delete_failed')
    end
  end

  private

  def check_admin
    redirect_to dashboard_path(locale: I18n.locale) unless current_user.admin?
  end
end
