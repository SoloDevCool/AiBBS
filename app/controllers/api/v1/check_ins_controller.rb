class Api::V1::CheckInsController < Api::V1::BaseController
  before_action :authenticate_user!

  def create
    result = CheckIn.check_in!(current_user)

    if result[:success]
      today_checked = current_user.check_ins.today.exists?

      render_success(
        data: {
          points_earned: result[:points],
          total_points: current_user.reload.points,
          today_checked_in: true
        },
        message: result[:message]
      )
    else
      render_business_error(result[:message], code: 10006)
    end
  end
end
