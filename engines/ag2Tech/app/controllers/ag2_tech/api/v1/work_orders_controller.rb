require_dependency "ag2_tech/application_controller"

module Ag2Tech
  #class Api::V1::WorkOrdersController < ApplicationController
  class Api::V1::WorkOrdersController < ::Api::V1::BaseController
    #include ActionView::Helpers::NumberHelper
    #before_filter :authenticate_user!
    #skip_load_and_authorize_resource
    #load_and_authorize_resource :class => WorkOrder
    #load_and_authorize_resource :class => false

    # ag2Tech API
    # returns JSON
    # scope => /ag2_tech
    # REST parameters => (<param>): optional
    #               project_id: project id
    #               id: work order id
    # URL parameters => <auth>: necessary
    #               user_email=...
    #               user_token=...
    # General:
    # GET /api/v1/work_orders/<method>[/<param>]?<auth>
    #
    # GET /api/v1/work_orders => all
    # GET /api/v1/work_orders/headers => headers (no items)
    # GET /api/v1/work_orders/:id => one
    # GET /api/v1/work_orders/headers/:id => header (one, no items)
    # GET /api/v1/work_orders/by_project/:project_id => by_project
    # GET /api/v1/work_orders/headers_by_project/:project_id => headers_by_project (no items)
    # GET /api/v1/work_orders/unstarted(/:project_id) => unstarted ones
    # GET /api/v1/work_orders/uncompleted(/:project_id) => started by uncompleted ones
    # GET /api/v1/work_orders/unclosed(/:project_id) => completed but unclosed ones
    # GET /api/v1/work_orders/closed(/:project_id) => closed ones
    #
    # GET /api/v1/work_order_areas/ => areas
    # GET /api/v1/work_order_areas/:id => area
    # GET /api/v1/work_order_types/ => types
    # GET /api/v1/work_order_types/:id => type
    # GET /api/v1/work_order_statuses/ => statuses
    # GET /api/v1/work_order_statuses/:id => status
    # GET /api/v1/work_order_labors/ => labors
    # GET /api/v1/work_order_labors/:id => labor

    # GET /api/work_orders
    def all
      work_orders = WorkOrder.by_no
      render json: serialized_work_orders(work_orders)
    end

    # GET /api/work_orders/headers/
    def headers
      work_orders = WorkOrder.by_no
      render json: serialized_work_orders_header(work_orders)
    end

    # GET /api/work_orders/:id
    def one
      if !is_numeric?(params[:id]) || params[:id] == '0'
        render json: :bad_request, status: :bad_request
      else
        work_order = WorkOrder.find(params[:id]) rescue nil
        if !work_order.blank?
          render json: Api::V1::WorkOrdersSerializer.new(work_order)
        else
          render json: :not_found, status: :not_found
        end
      end
    end

    # GET /api/work_orders/header/:id
    def header
      if !is_numeric?(params[:id]) || params[:id] == '0'
        render json: :bad_request, status: :bad_request
      else
        work_order = WorkOrder.find(params[:id]) rescue nil
        if !work_order.blank?
          render json: Api::V1::WorkOrdersHeaderSerializer.new(work_order, root: 'work_orders')
        else
          render json: :not_found, status: :not_found
        end
      end
    end

    # GET /api/work_orders/by_project/:project_id
    def by_project
      if params.has_key?(:project_id) && is_numeric?(params[:project_id]) && params[:project_id] != '0'
        work_orders = WorkOrder.belongs_to_project(params[:project_id])
        if !work_orders.blank?
          render json: serialized_work_orders(work_orders)
        else
          render json: :not_found, status: :not_found
        end
      else
        render json: :bad_request, status: :bad_request
      end
    end

    # GET /api/work_orders/headers_by_project/:project_id
    def headers_by_project
      if params.has_key?(:project_id) && is_numeric?(params[:project_id]) && params[:project_id] != '0'
        work_orders = WorkOrder.belongs_to_project(params[:project_id])
        if !work_orders.blank?
          render json: serialized_work_orders_header(work_orders)
        else
          render json: :not_found, status: :not_found
        end
      else
        render json: :bad_request, status: :bad_request
      end
    end

    # Unstarted
    # GET /api/work_orders/unstarted(/:project_id)
    def unstarted
      if params.has_key?(:project_id) && is_numeric?(params[:project_id]) && params[:project_id] != '0'
        work_orders = WorkOrder.unstarted(params[:project_id])
      else
        work_orders = WorkOrder.unstarted
      end
      if !work_orders.blank?
        render json: serialized_work_orders(work_orders)
      else
        render json: :not_found, status: :not_found
      end
    end

    # Started but uncompleted
    # GET /api/work_orders/uncompleted(/:project_id)
    def uncompleted
      if params.has_key?(:project_id) && is_numeric?(params[:project_id]) && params[:project_id] != '0'
        work_orders = WorkOrder.uncompleted(params[:project_id])
      else
        work_orders = WorkOrder.uncompleted
      end
      if !work_orders.blank?
        render json: serialized_work_orders(work_orders)
      else
        render json: :not_found, status: :not_found
      end
    end

    # Completed but unclosed
    # GET /api/work_orders/unclosed(/:project_id)
    def unclosed
      if params.has_key?(:project_id) && is_numeric?(params[:project_id]) && params[:project_id] != '0'
        work_orders = WorkOrder.unclosed(params[:project_id])
      else
        work_orders = WorkOrder.unclosed
      end
      if !work_orders.blank?
        render json: serialized_work_orders(work_orders)
      else
        render json: :not_found, status: :not_found
      end
    end

    # Closed
    # GET /api/work_orders/closed(/:project_id)
    def closed
      if params.has_key?(:project_id) && is_numeric?(params[:project_id]) && params[:project_id] != '0'
        work_orders = WorkOrder.closed(params[:project_id])
      else
        work_orders = WorkOrder.closed
      end
      if !work_orders.blank?
        render json: serialized_work_orders(work_orders)
      else
        render json: :not_found, status: :not_found
      end
    end

    #
    # Auxiliary models
    #
    # Work order Areas
    # GET /api/work_orders/areas
    def areas
      aux = WorkOrderArea.by_name
      render json: serialized_work_order_areas(aux)
    end

    # GET /api/work_orders/areas/:id
    def area
      if !is_numeric?(params[:id]) || params[:id] == '0'
        render json: :bad_request, status: :bad_request
      else
        aux = WorkOrderArea.find(params[:id]) rescue nil
        if !aux.blank?
          render json: Api::V1::WorkOrderAreasSerializer.new(aux)
        else
          render json: :not_found, status: :not_found
        end
      end
    end

    # Work order Types
    # GET /api/work_orders/types
    def types
      aux = WorkOrderType.by_name
      render json: serialized_work_order_types(aux)
    end

    # GET /api/work_orders/types/:id
    def type
      if !is_numeric?(params[:id]) || params[:id] == '0'
        render json: :bad_request, status: :bad_request
      else
        aux = WorkOrderType.find(params[:id]) rescue nil
        if !aux.blank?
          render json: Api::V1::WorkOrderTypesSerializer.new(aux)
        else
          render json: :not_found, status: :not_found
        end
      end
    end

    # Work order Statuses
    # GET /api/work_orders/statuses
    def statuses
      aux = WorkOrderStatus.by_name
      render json: serialized_work_order_statuses(aux)
    end

    # GET /api/work_orders/statuses/:id
    def status
      if !is_numeric?(params[:id]) || params[:id] == '0'
        render json: :bad_request, status: :bad_request
      else
        aux = WorkOrderStatus.find(params[:id]) rescue nil
        if !aux.blank?
          render json: Api::V1::WorkOrderStatusesSerializer.new(aux)
        else
          render json: :not_found, status: :not_found
        end
      end
    end

    # Work order Labors
    # GET /api/work_orders/labors
    def labors
      aux = WorkOrderLabor.by_name
      render json: serialized_work_order_labors(aux)
    end

    # GET /api/work_orders/labors/:id
    def labor
      if !is_numeric?(params[:id]) || params[:id] == '0'
        render json: :bad_request, status: :bad_request
      else
        aux = WorkOrderLabor.find(params[:id]) rescue nil
        if !aux.blank?
          render json: Api::V1::WorkOrderLaborsSerializer.new(aux)
        else
          render json: :not_found, status: :not_found
        end
      end
    end

    private

    # Returns JSON list of orders
    def serialized_work_orders(_orders)
      ActiveModel::ArraySerializer.new(_orders, each_serializer: Api::V1::WorkOrdersSerializer, root: 'work_orders')
    end

    def serialized_work_orders_header(_orders)
      ActiveModel::ArraySerializer.new(_orders, each_serializer: Api::V1::WorkOrdersHeaderSerializer, root: 'work_orders')
    end

    def serialized_work_order_areas(_aux)
      ActiveModel::ArraySerializer.new(_aux, each_serializer: Api::V1::WorkOrderAreasSerializer, root: 'work_order_areas')
    end

    def serialized_work_order_types(_aux)
      ActiveModel::ArraySerializer.new(_aux, each_serializer: Api::V1::WorkOrderTypesSerializer, root: 'work_order_types')
    end

    def serialized_work_order_statuses(_aux)
      ActiveModel::ArraySerializer.new(_aux, each_serializer: Api::V1::WorkOrderStatusesSerializer, root: 'work_order_statuses')
    end

    def serialized_work_order_labors(_aux)
      ActiveModel::ArraySerializer.new(_aux, each_serializer: Api::V1::WorkOrderLaborsSerializer, root: 'work_order_labors')
    end
  end
end
