module Effective
  class DatatablesController < ApplicationController
    skip_log_page_views quiet: true if defined?(EffectiveLogging)

    # This will respond to both a GET and a POST
    def show
      begin
        @datatable = find_datatable(params[:id]).try(:new) || raise('unable to find datatable')
        @datatable.view = view_context

        EffectiveDatatables.authorize!(self, :index, @datatable.collection_class)

        render json: @datatable.to_json
      rescue => e
        EffectiveDatatables.authorized?(self, :index, @datatable.try(:collection_class))

        render json: error_json(e)
      end
    end

    private

    def find_datatable(id)
      id = id.to_s.gsub(/-\d+\z/, '').gsub('-', '/')
      id.classify.safe_constantize || id.classify.pluralize.safe_constantize
    end

    def error_json(e)
      {
        data: [],
        draw: params[:draw].to_i,
        effective_datatables_error: (e.message.presence unless e.class.name.include?('ActiveRecord::')) || 'unexpected operation',
        recordsTotal: 0,
        recordsFiltered: 0,
        aggregates: [],
        charts: {}
      }
    end

  end
end
