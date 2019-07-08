# frozen_string_literal: true

class QueryConstructor
  def initialize(object, scope, query, context = {})
    @object = object
    @scope = scope
    @query = query
    @context = context
  end

  def construct
    joins = nil
    if @query['joins'].present?
      joins = @query['joins'].map do |j|
        if j.index(' ')
          j
        else
          j.to_sym
        end
      end
    end

    includes = nil
    if @query['includes'].present?
      includes = @query['includes'].map do |i|
        if i.is_a? String
          i.to_sym
        elsif i.is_a? Hash
          h = i.symbolize_keys
          h.each do |k, v|
            h[k] = v.map(&:to_sym)
          end
        end
      end
    end

    @scope = @scope.joins(joins) if joins
    if @query['wheres'].present?
      @scope = @scope.where(Liquid::Template.parse(@query['wheres'].map { |qi| "(#{qi})" }.join(' AND ')).render(@context.merge(@object.class.name.underscore => @object)))
    end
    @scope = @scope.includes(includes) if includes.present?
    @scope = @scope.order(Liquid::Template.parse(@query['order'].join(',')).render(@context.merge(@object.class.name.underscore => @object))) if @query['order'].present?

    Rails.logger.info "QueryConstructor - SQL query: #{@scope.to_sql}"
    @scope
  end
end
