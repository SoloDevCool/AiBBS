class CheckInsController < ApplicationController
  before_action :authenticate_user!

  def create
    result = CheckIn.check_in!(current_user)
    if result[:success]
      redirect_back fallback_location: profile_path, notice: result[:message]
    else
      redirect_back fallback_location: profile_path, alert: result[:message]
    end
  end
end
