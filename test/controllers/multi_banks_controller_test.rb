require 'test_helper'

class MultiBanksControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get multi_banks_index_url
    assert_response :success
  end

end
