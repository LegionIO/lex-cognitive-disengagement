# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveDisengagement
      module Runners
        module CognitiveDisengagement
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_disengagement_goal(label:, domain:, **)
            Legion::Logging.debug "[cognitive_disengagement] create_goal label=#{label} domain=#{domain}"
            goal = engine.create_goal(label: label, domain: domain)
            { success: true, goal: goal.to_h }
          end

          def check_goal_progress(goal_id:, new_progress:, effort: 0.1, **)
            Legion::Logging.debug "[cognitive_disengagement] check_progress goal_id=#{goal_id} " \
                                  "new_progress=#{new_progress} effort=#{effort}"
            delta = engine.check_progress(goal_id: goal_id, new_progress: new_progress, effort: effort)
            { success: true, goal_id: goal_id, delta: delta }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def assess_goal_disengagement(goal_id:, **)
            Legion::Logging.debug "[cognitive_disengagement] assess_goal goal_id=#{goal_id}"
            assessment = engine.assess_goal(goal_id: goal_id)
            { success: true, assessment: assessment }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def disengage_from_goal(goal_id:, reason:, **)
            Legion::Logging.debug "[cognitive_disengagement] disengage goal_id=#{goal_id} reason=#{reason}"
            goal = engine.disengage_goal(goal_id: goal_id, reason: reason)
            { success: true, goal: goal.to_h }
          rescue ArgumentError => e
            { success: false, error: e.message }
          end

          def stalled_goals_report(**)
            Legion::Logging.debug '[cognitive_disengagement] stalled_goals_report'
            goals = engine.stalled_goals
            { success: true, goals: goals.map(&:to_h), count: goals.size }
          end

          def active_goals_report(**)
            Legion::Logging.debug '[cognitive_disengagement] active_goals_report'
            goals = engine.active_goals
            { success: true, goals: goals.map(&:to_h), count: goals.size }
          end

          def most_invested_goals(limit: 5, **)
            Legion::Logging.debug "[cognitive_disengagement] most_invested_goals limit=#{limit}"
            goals = engine.most_invested(limit: limit)
            { success: true, goals: goals.map(&:to_h), count: goals.size }
          end

          def highest_disengage_candidates(limit: 5, **)
            Legion::Logging.debug "[cognitive_disengagement] highest_disengage_candidates limit=#{limit}"
            goals = engine.highest_disengage_score(limit: limit)
            { success: true, goals: goals.map(&:to_h), count: goals.size }
          end

          def update_cognitive_disengagement(**)
            Legion::Logging.debug '[cognitive_disengagement] decay_all'
            engine.decay_all
            { success: true, stats: engine.to_h }
          end

          def cognitive_disengagement_stats(**)
            Legion::Logging.debug '[cognitive_disengagement] stats'
            { success: true, stats: engine.to_h }
          end

          private

          def engine
            @engine ||= Helpers::DisengagementEngine.new
          end
        end
      end
    end
  end
end
