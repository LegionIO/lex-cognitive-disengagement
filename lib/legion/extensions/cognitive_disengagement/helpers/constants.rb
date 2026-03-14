# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDisengagement
      module Helpers
        module Constants
          GOAL_STATES = %i[active monitoring stalled disengaging disengaged].freeze
          DISENGAGE_REASONS = %i[
            sunk_cost
            low_progress
            opportunity_cost
            goal_conflict
            resource_exhaustion
            external_block
          ].freeze

          STATE_LABELS = {
            active:      :pursuing,
            monitoring:  :watching,
            stalled:     :struggling,
            disengaging: :withdrawing,
            disengaged:  :released
          }.freeze

          MAX_GOALS   = 100
          MAX_HISTORY = 300

          STALL_THRESHOLD     = 0.1   # progress per check below this = stalled
          DISENGAGE_THRESHOLD = 0.05  # progress below this after multiple checks triggers disengage recommendation

          SUNK_COST_WEIGHT        = 0.3 # how much sunk cost resists disengagement (bias to overcome)
          OPPORTUNITY_COST_WEIGHT = 0.4
          PROGRESS_WEIGHT         = 0.3

          DEFAULT_INVESTMENT = 0.0
          DEFAULT_PROGRESS   = 0.0

          DECAY_RATE = 0.02
        end
      end
    end
  end
end
