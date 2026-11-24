# frozen_string_literal: true

module Nuntius
  # What a template's or campaign's message is only sent on: "if [all] of the
  # following conditions are met: [screening.state] [is] [processed]", a rule's
  # variable one of the design's Liquid variables (see Variables). They're
  # Liquidum's (Liquidum::Conditions), which the browser has too.
  Conditions = Liquidum::Conditions
end
