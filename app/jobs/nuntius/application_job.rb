module Nuntius
  class ApplicationJob < ActiveJob::Base
    retry_on ActiveJob::DeserializationError
    retry_on ActiveRecord::Deadlocked
    queue_as Nuntius.config.jobs_queue_name
  end
end
