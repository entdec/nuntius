# frozen_string_literal: true

module Nuntius
  class ApplicationService < Servitium::Service
    transactional true
  end
end
