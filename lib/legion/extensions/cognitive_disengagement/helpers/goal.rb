# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveDisengagement
      module Helpers
        class Goal
          include Constants

          attr_reader :id, :label, :domain, :state, :progress, :investment,
                      :progress_history, :created_at, :last_checked_at, :disengage_reason

          def initialize(label:, domain:)
            @id               = SecureRandom.uuid
            @label            = label
            @domain           = domain
            @state            = :active
            @progress         = DEFAULT_PROGRESS
            @investment       = DEFAULT_INVESTMENT
            @progress_history = []
            @created_at       = Time.now.utc
            @last_checked_at  = Time.now.utc
            @disengage_reason = nil
          end

          def check_progress!(new_progress:, effort:)
            clamped = new_progress.clamp(0.0, 1.0)
            delta   = clamped - @progress
            @progress_history << delta
            @progress_history.shift while @progress_history.size > MAX_HISTORY
            @progress         = clamped
            @investment      += effort
            @last_checked_at  = Time.now.utc
            delta
          end

          def stalled?
            return false if @progress_history.size < 3

            @progress_history.last(3).all? { |d| d < STALL_THRESHOLD }
          end

          def recommend_disengage?
            stalled? && disengagement_score > 0.6
          end

          def disengagement_score
            raw = ((1.0 - recent_progress_rate) * PROGRESS_WEIGHT) +
                  (opportunity_cost_estimate * OPPORTUNITY_COST_WEIGHT) -
                  (sunk_cost_resistance * SUNK_COST_WEIGHT)
            raw.clamp(0.0, 1.0)
          end

          def sunk_cost_resistance
            @investment / (@investment + 1.0)
          end

          def opportunity_cost_estimate
            1.0 - @progress
          end

          def recent_progress_rate
            return 0.0 if @progress_history.empty?

            last = @progress_history.last(3)
            last.sum / last.size.to_f
          end

          def disengage!(reason:)
            @state            = :disengaged
            @disengage_reason = reason
          end

          def to_h
            {
              id:                   @id,
              label:                @label,
              domain:               @domain,
              state:                @state,
              state_label:          STATE_LABELS[@state],
              progress:             @progress.round(4),
              investment:           @investment.round(4),
              stalled:              stalled?,
              recommend_disengage:  recommend_disengage?,
              disengagement_score:  disengagement_score.round(4),
              sunk_cost_resistance: sunk_cost_resistance.round(4),
              opportunity_cost:     opportunity_cost_estimate.round(4),
              recent_progress_rate: recent_progress_rate.round(4),
              history_size:         @progress_history.size,
              disengage_reason:     @disengage_reason,
              created_at:           @created_at,
              last_checked_at:      @last_checked_at
            }
          end
        end
      end
    end
  end
end
