require 'test_helper'

class Administrative::LoginControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get administrative_login_index_url
    assert_response :success
  end

end
