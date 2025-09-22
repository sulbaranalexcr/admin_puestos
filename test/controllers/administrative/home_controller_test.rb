require 'test_helper'

class Administrative::HomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get administrative_home_index_url
    assert_response :success
  end

end
