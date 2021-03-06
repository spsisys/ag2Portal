require 'test_helper'

module Ag2HelpDesk
  class TicketStatusesControllerTest < ActionController::TestCase
    setup do
      @ticket_status = ticket_statuses(:one)
    end
  
    test "should get index" do
      get :index
      assert_response :success
      assert_not_nil assigns(:ticket_statuses)
    end
  
    test "should get new" do
      get :new
      assert_response :success
    end
  
    test "should create ticket_status" do
      assert_difference('TicketStatus.count') do
        post :create, ticket_status: {  }
      end
  
      assert_redirected_to ticket_status_path(assigns(:ticket_status))
    end
  
    test "should show ticket_status" do
      get :show, id: @ticket_status
      assert_response :success
    end
  
    test "should get edit" do
      get :edit, id: @ticket_status
      assert_response :success
    end
  
    test "should update ticket_status" do
      put :update, id: @ticket_status, ticket_status: {  }
      assert_redirected_to ticket_status_path(assigns(:ticket_status))
    end
  
    test "should destroy ticket_status" do
      assert_difference('TicketStatus.count', -1) do
        delete :destroy, id: @ticket_status
      end
  
      assert_redirected_to ticket_statuses_path
    end
  end
end
