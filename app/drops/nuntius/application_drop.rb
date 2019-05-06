# frozen_string_literal: true

module Nuntius
  class ApplicationDrop < Liquid::Drop
    def initialize(object)
      @object = object
    end

    def to_gid
      @object.to_gid
    end

    def to_sgid
      @object.to_sgid
    end
  end
end
