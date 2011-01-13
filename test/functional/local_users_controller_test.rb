require 'test_helper'

class LocalUsersControllerTest < ActionController::TestCase
  setup do
    @local_user = local_users(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:local_users)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create local_user" do
    assert_difference('LocalUser.count') do
      post :create, :local_user => @local_user.attributes
    end

    assert_redirected_to local_user_path(assigns(:local_user))
  end

  test "should show local_user" do
    get :show, :id => @local_user.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @local_user.to_param
    assert_response :success
  end

  test "should update local_user" do
    put :update, :id => @local_user.to_param, :local_user => @local_user.attributes
    assert_redirected_to local_user_path(assigns(:local_user))
  end

  test "should destroy local_user" do
    assert_difference('LocalUser.count', -1) do
      delete :destroy, :id => @local_user.to_param
    end

    assert_redirected_to local_users_path
  end
end
