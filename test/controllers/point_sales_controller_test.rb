require 'test_helper'

class PointSalesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get point_sales_index_url
    assert_response :success
  end

  test "should get show" do
    get point_sales_show_url
    assert_response :success
  end

end
