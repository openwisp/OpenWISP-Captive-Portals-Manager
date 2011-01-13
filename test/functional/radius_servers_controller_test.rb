require 'test_helper'

class RadiusServersControllerTest < ActionController::TestCase
  setup do
    @radius_auth_server = radius_auth_servers(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:radius_auth_servers)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create radius_auth_server" do
    assert_difference('RadiusAuthServer.count') do
      post :create, :radius_auth_server => @radius_auth_server.attributes
    end

    assert_redirected_to radius_auth_server_path(assigns(:radius_auth_server))
  end

  test "should show radius_auth_server" do
    get :show, :id => @radius_auth_server.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @radius_auth_server.to_param
    assert_response :success
  end

  test "should update radius_auth_server" do
    put :update, :id => @radius_auth_server.to_param, :radius_auth_server => @radius_auth_server.attributes
    assert_redirected_to radius_auth_server_path(assigns(:radius_auth_server))
  end

  test "should destroy radius_auth_server" do
    assert_difference('RadiusAuthServer.count', -1) do
      delete :destroy, :id => @radius_auth_server.to_param
    end

    assert_redirected_to radius_auth_servers_path
  end
end
