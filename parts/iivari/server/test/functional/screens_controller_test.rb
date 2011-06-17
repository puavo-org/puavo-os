require 'test_helper'

class ScreensControllerTest < ActionController::TestCase
=begin
  setup do
    @screen = screens(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:screens)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create screen" do
    assert_difference('Screen.count') do
      post :create, :screen => @screen.attributes
    end

    assert_redirected_to screen_path(assigns(:screen))
  end

  test "should show screen" do
    get :show, :id => @screen.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @screen.to_param
    assert_response :success
  end

  test "should update screen" do
    put :update, :id => @screen.to_param, :screen => @screen.attributes
    assert_redirected_to screen_path(assigns(:screen))
  end

  test "should destroy screen" do
    assert_difference('Screen.count', -1) do
      delete :destroy, :id => @screen.to_param
    end

    assert_redirected_to screens_path
  end
=end
end
