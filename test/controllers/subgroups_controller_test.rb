require 'test_helper'

class SubgroupsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get subgroups_index_url
    assert_response :success
  end

  test "should get show" do
    get subgroups_show_url
    assert_response :success
  end

end
