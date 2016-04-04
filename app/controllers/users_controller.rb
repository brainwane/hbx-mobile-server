class UsersController < ApplicationController
#  before_action :set_user, only: [:show, :edit, :update, :destroy]
 # http_basic_authenticate_with :name => "myfinance", :password => "credit123"

  skip_before_filter :authenticate_user! # we do not need devise authentication here
  before_filter :fetch_user, :except => [:index, :create]

  # GET /users
  # GET /users.json
  def index
 #       render text: "Thanks for sending a GETTING request with cURL! Payload: #{request.body.read}"
 #   @users = User.all
      @user = User.find(params[:email])
   #   if user
        render :json => @user
    #  else
     #   logger.debug "no user"
      # end
  end

  # GET /users/1
  # GET /users/1.json
  def show
    render text: "Thanks for sending a GETTING/SHOWING request with cURL! Payload: #{request.body.read}"
  end

  # GET /users/new
  def new
    @user = User.new
  end

  # GET /users/1/edit
  def edit
  end

  # POST /users
  # POST /users.json
  def create
    logger.debug "%%%%%"
    render text: "Thanks for sending a POST request with cURL! Payload: #{request.body.read}"
  #  @user = User.new(user_params)
  ##  @user = User.where(email: params[:email])
 # @user = User.new(params[:user])
  #@user.temp_password = Devise.friendly_token
  
   #   if @user.email
    #    render :json {error: "HERE; check the submitted email address"}
     # else
    ##     render :json => @user
      # end

    #render :json => @user

#    respond_to do |format|
 #     if @user.save
  #      format.html { redirect_to @user, notice: 'User was successfully created.' }
  #      format.json { render :show, status: :created, location: @user }
  #    else
   #     format.html { render :new }
   #     format.json { render json: @user.errors, status: :unprocessable_entity }
   #   end
    #end
  end

  # PATCH/PUT /users/1
  # PATCH/PUT /users/1.json
 # def update
 #   respond_to do |format|
 #     if @user.update(user_params)
 #       format.html { redirect_to @user, notice: 'User was successfully updated.' }
 #       format.json { render :show, status: :ok, location: @user }
 #     else
 #       format.html { render :edit }
 #       format.json { render json: @user.errors, status: :unprocessable_entity }
 #     end
 #   end
 # end

  # DELETE /users/1
  # DELETE /users/1.json
 # def destroy
 #   @user.destroy
 #   respond_to do |format|
 #     format.html { redirect_to users_url, notice: 'User was successfully destroyed.' }
 #     format.json { head :no_content }
 #   end
 # end

  private
    # Use callbacks to share common setup or constraints between actions.
 #   def set_user
 #     @user = User.find(params[:id])
 #   end

    # Never trust parameters from the scary internet, only allow the white list through.
    def user_params
 #     params.require(:user).permit(:first_name, :last_name, :email, :password)
#    def article_params
            #     params.require(:article).permit(:title, :text, :author)
            {
                email: params[:email],
                password: params[:password],
     #           author: params[:author]
            }
#    end
    end
end
