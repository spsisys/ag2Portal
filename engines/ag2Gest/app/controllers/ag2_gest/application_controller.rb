module Ag2Gest
  class ApplicationController < ::ApplicationController
    mattr_accessor :reset_session_variables_for_filters

    layout 'layouts/application'

    def reset_session_variables_for_filters
      session[:search] = nil
      session[:letter] = nil
      session[:active_tab] = nil
      session[:No] = nil
      session[:NoCR] = nil
      session[:name] = nil
      session[:Type] = nil
      session[:Status] = nil
      session[:sub_office] = nil
      session[:WrkrOffice] = nil
      session[:sort] = nil
      session[:direction] = nil
      session[:ifilter] = nil
      session[:ifilter_show] = nil
      session[:ifilter_show_tariff] = nil
      session[:ifilter_index_tariff] = nil
      session[:ifilter_show_account] = nil
      session[:page_entries_show] = nil
      session[:Period] = nil
      session[:PeriodB] = nil
      session[:Group] = nil
      session[:Project] = nil
      session[:ProjectB] = nil
      session[:Client] = nil
      session[:ClientB] = nil
      session[:Subscriber] = nil
      session[:SubscriberB] = nil
      session[:Operation] = nil
      session[:Biller] = nil
      session[:BillerB] = nil
      session[:entity] = nil
      session[:Request] = nil
      session[:ReadingRoute] = nil
      session[:Meter] = nil
      session[:Order] = nil
      session[:Caliber] = nil
      session[:RequestType] = nil
      session[:RequestStatus] = nil
      session[:ClientInfo] = nil
      session[:ServicePoint] = nil
      session[:ServicePointB] = nil
      session[:SubscriberCode] = nil
      session[:ClientCode] = nil
      session[:SubscriberFiscal] = nil
      session[:ClientFiscal] = nil
      session[:StreetName] = nil
      session[:StreetNameB] = nil
      session[:BankAccount] = nil
      session[:BankOrder] = nil
      session[:Use] = nil
      session[:TariffType] = nil
      session[:Phase] = nil
      session[:User] = nil
      session[:incidences] = nil
      session[:From] = nil
      session[:To] = nil
      session[:BillNo] = nil
    end

    def current_projects
      if session[:office] != '0'
        _projects = Project.where(office_id: session[:office].to_i).order(:project_code)
      elsif session[:company] != '0'
        _projects = Project.where(company_id: session[:company].to_i).order(:project_code)
      else
        _projects = session[:organization] != '0' ? Project.where(organization_id: session[:organization].to_i).order(:project_code) : Project.order(:project_code)
      end
    end

    def current_projects_ids
      current_projects.pluck(:id)
    end

    def current_offices_ids
      if session[:office] != '0'
        _offices = [session[:office]]
      elsif session[:company] != '0'
        _offices = Company.find(session[:company]).offices.pluck('offices.town_id')
      else
        _offices = session[:organization] != '0' ? Organization.find(session[:organization]).offices.pluck('offices.town_id') : Office.pluck(:id)
      end
    end

    def current_offices
      if session[:office] != '0'
        _offices = Office.where(id: session[:office])
      elsif session[:company] != '0'
        _offices = Company.find(session[:company]).offices
      else
        _offices = session[:organization] != '0' ? Organization.find(session[:organization]).offices : Office.order(:id)
      end
    end
  end
end
