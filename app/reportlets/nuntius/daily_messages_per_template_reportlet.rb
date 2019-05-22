# frozen_string_literal: true

require_dependency 'nuntius/application_reportlet'

module Nuntius
  class DailyMessagesPerTemplateReportlet < ApplicationReportlet
    title 'Daily messages per template'
    cache 1.minute

    def table_data
      data = [[''] + ymds(true)]

      matrix = all_templates.map do |template|
        tmpl = Nuntius::Template.find(template)
        if tmpl
          template_ymd_totals = ymds.map { |ymd| ymd_template_id(ymd, template, :count) }
          [tmpl.description] + template_ymd_totals
        end
      end

      if matrix.present?
        data += matrix
      else
        data = []
      end
      data
    end

    private

    def results
      return @results if @results

      select_manager = messages.project(
        :template_id,
        Arel.sql("CONCAT(EXTRACT(YEAR FROM created_at :: DATE) :: VARCHAR, '-', EXTRACT(MONTH FROM created_at :: DATE) :: VARCHAR, '-', EXTRACT(DAY FROM created_at :: DATE) :: VARCHAR) AS ymd"),
        Arel.star.count
      )

      select_manager = select_manager.where(messages[:template_id].in(template_ids))
      select_manager = select_manager.where(messages[:created_at].between(14.days.ago..Time.now))

      select_manager = select_manager.group(:template_id, :ymd)
      select_manager = select_manager.order(:template_id, :ymd)

      Rails.logger.info select_manager.to_sql
      @results = ActiveRecord::Base.connection.execute(select_manager.to_sql)
    end
  end
end
