require 'test_helper'

class AllowedTrafficsControllerTest < ActionController::TestCase
  setup do
    @allowed_traffic = allowed_traffics(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:allowed_traffics)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create allowed_traffic" do
    assert_difference('AllowedTraffic.count') do
      post :create, :allowed_traffic => @allowed_traffic.attributes
    end

    assert_redirected_to allowed_traffic_path(assigns(:allowed_traffic))
  end

  test "should show allowed_traffic" do
    get :show, :id => @allowed_traffic.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @allowed_traffic.to_param
    assert_response :success
  end

  test "should update allowed_traffic" do
    put :update, :id => @allowed_traffic.to_param, :allowed_traffic => @allowed_traffic.attributes
    assert_redirected_to allowed_traffic_path(assigns(:allowed_traffic))
  end

  test "should destroy allowed_traffic" do
    assert_difference('AllowedTraffic.count', -1) do
      delete :destroy, :id => @allowed_traffic.to_param
    end

    assert_redirected_to allowed_traffics_path
  end
end
