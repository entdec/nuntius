class User < ApplicationRecord
  state_machine initial: :pending do
    event :activate do
      transition %i[disabled pending] => :active
    end

    event :disable do
      transition active: :disabled
    end
  end
  nuntiable use_state_machine: true
end
