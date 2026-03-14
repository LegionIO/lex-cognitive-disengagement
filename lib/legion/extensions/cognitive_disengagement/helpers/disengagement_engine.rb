# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDisengagement
      module Helpers
        class DisengagementEngine
          include Constants

          def initialize
            @goals = {}
          end

          def create_goal(label:, domain:)
            goal = Goal.new(label: label, domain: domain)
            @goals[goal.id] = goal
            goal
          end

          def check_progress(goal_id:, new_progress:, effort:)
            goal = fetch_goal!(goal_id)
            goal.check_progress!(new_progress: new_progress, effort: effort)
          end

          def assess_goal(goal_id:)
            goal = fetch_goal!(goal_id)
            {
              id:                   goal.id,
              label:                goal.label,
              domain:               goal.domain,
              state:                goal.state,
              progress:             goal.progress.round(4),
              investment:           goal.investment.round(4),
              stalled:              goal.stalled?,
              recommend_disengage:  goal.recommend_disengage?,
              disengagement_score:  goal.disengagement_score.round(4),
              sunk_cost_resistance: goal.sunk_cost_resistance.round(4),
              opportunity_cost:     goal.opportunity_cost_estimate.round(4)
            }
          end

          def disengage_goal(goal_id:, reason:)
            goal = fetch_goal!(goal_id)
            goal.disengage!(reason: reason)
            goal
          end

          def stalled_goals
            @goals.values.select(&:stalled?)
          end

          def active_goals
            @goals.values.select { |g| g.state == :active }
          end

          def disengaged_goals
            @goals.values.select { |g| g.state == :disengaged }
          end

          def goals_by_domain(domain:)
            @goals.values.select { |g| g.domain == domain }
          end

          def most_invested(limit: 5)
            @goals.values.sort_by { |g| -g.investment }.first(limit)
          end

          def highest_disengage_score(limit: 5)
            @goals.values.sort_by { |g| -g.disengagement_score }.first(limit)
          end

          def decay_all
            active_goals.each do |goal|
              new_progress = (goal.progress - DECAY_RATE).clamp(0.0, 1.0)
              goal.check_progress!(new_progress: new_progress, effort: 0.0)
            end
          end

          def to_h
            {
              total_goals:      @goals.size,
              active_goals:     active_goals.size,
              stalled_goals:    stalled_goals.size,
              disengaged_goals: disengaged_goals.size
            }
          end

          private

          def fetch_goal!(goal_id)
            @goals.fetch(goal_id) { raise ArgumentError, "Unknown goal_id: #{goal_id}" }
          end
        end
      end
    end
  end
end
