require 'test_helper'
require 'authlogic/test_case'

class ApiControllerTest < ActionController::TestCase
  include Authlogic::TestCase
  
  setup :activate_authlogic
  
  test "should get temporary_login" do
    get :temporary_login
    assert_response :success
  end

end