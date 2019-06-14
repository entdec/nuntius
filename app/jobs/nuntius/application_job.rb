module Nuntius
  class ApplicationJob < ActiveJob::Base
    retry_on ActiveJob::DeserializationError
    retry_on ActiveRecord::Deadlocked
  end
end
