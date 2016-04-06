class VisitsController < ApplicationController

	def create
		print params_for_create
		render :json => {session_key: "23GHJ678"}
	end

	def params_for_create
		params.permit(:email, :password, :device_id)
	end

end
