module Nuntius
  class ApplicationJob < ::ApplicationJob
    retry_on ActiveJob::DeserializationError
    retry_on ActiveRecord::Deadlocked
  end
end
