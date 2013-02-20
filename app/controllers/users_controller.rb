class UsersController < ApplicationController

  def home
    @user = User.new
    
    if params[:commit] == 'Login'
      login
    elsif params[:commit] == 'Add'
      add
    else
      respond_to do |format|
        format.html 
      end
    end
  end

  def login
    @user = User.authenticate(params[:username], params[:password])

    errCode = 0
    jsonResult = {}
    
    if @user.nil?
      errCode = -1
      flash[:notice] = "Invalid username and password combination. Please try again." 
    else
      errCode = 1
      flash[:notice] = nil
      @user.count += 1
      @user.save
      jsonResult[:count] = @user.count
    end

    jsonResult[:errCode] = errCode
    respond_to do |format|
      format.html { render (errCode == 1 ? :profile : :home) }
      format.json { render json: jsonResult }
    end
  end

  def add
    @user = User.new
    @user.username = params[:username]
    @user.password = params[:password]
    @user.count = 1
    
    errCode = 0
    jsonResult = {}

    if @user.save
      errCode = 1
      flash[:notice] = nil
      jsonResult[:count] = 1
    elsif @user.username.nil? or @user.username == "" or @user.username.length > 128
      errCode = -3 # ERR_BAD_USERNAME
      flash[:notice] = "The user name should be non-empty and at most 128 characters long. Please try again." 
    elsif @user.password.length > 128
      errCode = -4 # ERR_BAD_PASSWORD
      flash[:notice] = "The password should be at most 128 characters long. Please try again." 
    else
      errCode = -2 # ERR_USER_EXISTS
      flash[:notice] = "This user name already exists. Please try again."
    end

    jsonResult[:errCode] = errCode
    respond_to do |format|
      format.html { render (errCode == 1 ? :profile : :home) }
      format.json { render json: jsonResult }
    end
  end

  def resetFixture
    User.delete_all
    respond_to do |format|
      format.json { render json: {errCode: 1} }
    end
  end

  def unitTests
    output = `rspec`
    total = /(\d+) example[s]/.match(output)[1]
    failed = /(\d+) failure[s]/.match(output)[1]
    respond_to do |format|
      format.json { render json: {totalTests: total, nrFailed: failed, output: output} }
    end
  end
end