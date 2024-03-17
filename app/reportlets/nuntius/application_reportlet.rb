# frozen_string_literal: true

module Nuntius
  class ApplicationReportlet < Trado::Reportlet
    attr_reader :template_ids

    def initialize(params)
      super
      @template_ids = params[:template_ids]&.split(",")
    end

    private

    def ymds(_for_display = false)
      results.map { |r| r["ymd"] }.uniq.sort_by { |w| Date.strptime(w, "%F") }
    end

    def all_templates
      map_items(results, :template_id)
    end

    # Helper to get item for ymd, template_id
    def ymd_template_id(ymd, template_id, what)
      find_item(results, {ymd: ymd, template_id: template_id}, what)
    end

    # Arel helpers
    def templates
      Nuntius::Template.arel_table
    end

    def messages
      Nuntius::Message.arel_table
    end
  end
end
