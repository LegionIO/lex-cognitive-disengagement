# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::CognitiveDisengagement::Helpers::DisengagementEngine do
  subject(:engine) { described_class.new }

  let(:goal) { engine.create_goal(label: 'Write tests', domain: 'development') }

  describe '#create_goal' do
    it 'returns a Goal instance' do
      expect(goal).to be_a(Legion::Extensions::CognitiveDisengagement::Helpers::Goal)
    end

    it 'stores the goal internally' do
      created = goal
      expect(engine.active_goals).to include(created)
    end

    it 'assigns a unique id each time' do
      g2 = engine.create_goal(label: 'Another', domain: 'dev')
      expect(goal.id).not_to eq(g2.id)
    end
  end

  describe '#check_progress' do
    it 'returns the delta' do
      delta = engine.check_progress(goal_id: goal.id, new_progress: 0.3, effort: 0.5)
      expect(delta).to be_within(0.001).of(0.3)
    end

    it 'updates the goal progress' do
      engine.check_progress(goal_id: goal.id, new_progress: 0.5, effort: 0.2)
      expect(goal.progress).to eq(0.5)
    end

    it 'raises ArgumentError for unknown goal_id' do
      expect { engine.check_progress(goal_id: 'bad-id', new_progress: 0.1, effort: 0.1) }
        .to raise_error(ArgumentError, /Unknown goal_id/)
    end
  end

  describe '#assess_goal' do
    it 'returns a hash with assessment keys' do
      result = engine.assess_goal(goal_id: goal.id)
      expect(result).to include(
        :id, :label, :domain, :state, :progress, :investment,
        :stalled, :recommend_disengage, :disengagement_score,
        :sunk_cost_resistance, :opportunity_cost
      )
    end

    it 'raises ArgumentError for unknown goal_id' do
      expect { engine.assess_goal(goal_id: 'missing') }
        .to raise_error(ArgumentError)
    end

    it 'reflects current goal state' do
      engine.check_progress(goal_id: goal.id, new_progress: 0.4, effort: 1.0)
      result = engine.assess_goal(goal_id: goal.id)
      expect(result[:progress]).to be_within(0.001).of(0.4)
    end
  end

  describe '#disengage_goal' do
    it 'transitions goal to :disengaged' do
      engine.disengage_goal(goal_id: goal.id, reason: :low_progress)
      expect(goal.state).to eq(:disengaged)
    end

    it 'returns the updated goal' do
      result = engine.disengage_goal(goal_id: goal.id, reason: :sunk_cost)
      expect(result).to eq(goal)
    end

    it 'raises ArgumentError for unknown goal_id' do
      expect { engine.disengage_goal(goal_id: 'nope', reason: :sunk_cost) }
        .to raise_error(ArgumentError)
    end
  end

  describe '#stalled_goals' do
    it 'returns empty when no goals are stalled' do
      expect(engine.stalled_goals).to be_empty
    end

    it 'returns goals where stalled? is true' do
      3.times { engine.check_progress(goal_id: goal.id, new_progress: 0.01, effort: 0.1) }
      expect(engine.stalled_goals).to include(goal)
    end

    it 'excludes goals with good progress' do
      3.times { |i| engine.check_progress(goal_id: goal.id, new_progress: (i + 1) * 0.2, effort: 0.1) }
      expect(engine.stalled_goals).not_to include(goal)
    end
  end

  describe '#active_goals' do
    it 'includes newly created goals' do
      created = goal
      expect(engine.active_goals).to include(created)
    end

    it 'excludes disengaged goals' do
      engine.disengage_goal(goal_id: goal.id, reason: :sunk_cost)
      expect(engine.active_goals).not_to include(goal)
    end
  end

  describe '#disengaged_goals' do
    it 'is empty before any disengagement' do
      goal
      expect(engine.disengaged_goals).to be_empty
    end

    it 'includes goals after disengagement' do
      engine.disengage_goal(goal_id: goal.id, reason: :resource_exhaustion)
      expect(engine.disengaged_goals).to include(goal)
    end
  end

  describe '#goals_by_domain' do
    it 'returns only goals in the given domain' do
      created = goal
      engine.create_goal(label: 'Other', domain: 'finance')
      result = engine.goals_by_domain(domain: 'development')
      expect(result).to include(created)
      expect(result.map(&:domain).uniq).to eq(['development'])
    end

    it 'returns empty for unknown domain' do
      expect(engine.goals_by_domain(domain: 'nonexistent')).to be_empty
    end
  end

  describe '#most_invested' do
    before do
      engine.check_progress(goal_id: goal.id, new_progress: 0.3, effort: 10.0)
      g2 = engine.create_goal(label: 'B', domain: 'd')
      engine.check_progress(goal_id: g2.id, new_progress: 0.2, effort: 1.0)
    end

    it 'returns goals sorted by investment descending' do
      result = engine.most_invested(limit: 2)
      expect(result.first.investment).to be >= result.last.investment
    end

    it 'respects limit' do
      5.times { engine.create_goal(label: 'Extra', domain: 'd') }
      expect(engine.most_invested(limit: 3).size).to be <= 3
    end
  end

  describe '#highest_disengage_score' do
    before do
      3.times { engine.check_progress(goal_id: goal.id, new_progress: 0.01, effort: 0.0) }
      g2 = engine.create_goal(label: 'High progress', domain: 'd')
      engine.check_progress(goal_id: g2.id, new_progress: 0.9, effort: 5.0)
    end

    it 'returns goals sorted by disengagement_score descending' do
      result = engine.highest_disengage_score(limit: 2)
      expect(result.first.disengagement_score).to be >= result.last.disengagement_score
    end

    it 'respects limit' do
      5.times { engine.create_goal(label: 'E', domain: 'd') }
      expect(engine.highest_disengage_score(limit: 2).size).to be <= 2
    end
  end

  describe '#decay_all' do
    it 'reduces progress on active goals' do
      engine.check_progress(goal_id: goal.id, new_progress: 0.5, effort: 0.1)
      before_progress = goal.progress
      engine.decay_all
      expect(goal.progress).to be < before_progress
    end

    it 'does not affect disengaged goals' do
      engine.check_progress(goal_id: goal.id, new_progress: 0.5, effort: 0.1)
      engine.disengage_goal(goal_id: goal.id, reason: :sunk_cost)
      before_progress = goal.progress
      engine.decay_all
      expect(goal.progress).to eq(before_progress)
    end

    it 'clamps progress at 0.0' do
      engine.decay_all
      expect(goal.progress).to eq(0.0)
    end
  end

  describe '#to_h' do
    it 'returns counts hash' do
      h = engine.to_h
      expect(h).to include(:total_goals, :active_goals, :stalled_goals, :disengaged_goals)
    end

    it 'reflects created goal in total_goals' do
      goal
      expect(engine.to_h[:total_goals]).to eq(1)
    end

    it 'updates after disengagement' do
      goal
      engine.disengage_goal(goal_id: goal.id, reason: :low_progress)
      h = engine.to_h
      expect(h[:active_goals]).to eq(0)
      expect(h[:disengaged_goals]).to eq(1)
    end
  end
end
