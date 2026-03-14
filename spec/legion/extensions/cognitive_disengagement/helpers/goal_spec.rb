# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::CognitiveDisengagement::Helpers::Goal do
  subject(:goal) { described_class.new(label: 'Learn Ruby', domain: 'education') }

  describe '#initialize' do
    it 'assigns a uuid id' do
      expect(goal.id).to match(/\A[0-9a-f-]{36}\z/)
    end

    it 'assigns label' do
      expect(goal.label).to eq('Learn Ruby')
    end

    it 'assigns domain' do
      expect(goal.domain).to eq('education')
    end

    it 'starts in :active state' do
      expect(goal.state).to eq(:active)
    end

    it 'starts with zero progress' do
      expect(goal.progress).to eq(0.0)
    end

    it 'starts with zero investment' do
      expect(goal.investment).to eq(0.0)
    end

    it 'starts with empty progress_history' do
      expect(goal.progress_history).to be_empty
    end

    it 'records created_at' do
      expect(goal.created_at).to be_a(Time)
    end

    it 'records last_checked_at' do
      expect(goal.last_checked_at).to be_a(Time)
    end

    it 'has no disengage_reason initially' do
      expect(goal.disengage_reason).to be_nil
    end
  end

  describe '#check_progress!' do
    it 'returns the delta' do
      delta = goal.check_progress!(new_progress: 0.3, effort: 0.5)
      expect(delta).to be_within(0.001).of(0.3)
    end

    it 'updates progress' do
      goal.check_progress!(new_progress: 0.4, effort: 0.2)
      expect(goal.progress).to eq(0.4)
    end

    it 'accumulates investment' do
      goal.check_progress!(new_progress: 0.1, effort: 1.0)
      goal.check_progress!(new_progress: 0.2, effort: 2.0)
      expect(goal.investment).to be_within(0.001).of(3.0)
    end

    it 'appends delta to progress_history' do
      goal.check_progress!(new_progress: 0.2, effort: 0.1)
      expect(goal.progress_history.size).to eq(1)
    end

    it 'records negative deltas when progress drops' do
      goal.check_progress!(new_progress: 0.5, effort: 0.1)
      delta = goal.check_progress!(new_progress: 0.3, effort: 0.1)
      expect(delta).to be < 0.0
    end

    it 'clamps new_progress to 0..1' do
      goal.check_progress!(new_progress: 1.5, effort: 0.1)
      expect(goal.progress).to eq(1.0)
      goal.check_progress!(new_progress: -0.5, effort: 0.1)
      expect(goal.progress).to eq(0.0)
    end

    it 'caps history at MAX_HISTORY' do
      max = Legion::Extensions::CognitiveDisengagement::Helpers::Constants::MAX_HISTORY
      (max + 10).times { |i| goal.check_progress!(new_progress: (i % 10) * 0.1, effort: 0.01) }
      expect(goal.progress_history.size).to eq(max)
    end

    it 'updates last_checked_at' do
      before = goal.last_checked_at
      sleep(0.01)
      goal.check_progress!(new_progress: 0.1, effort: 0.1)
      expect(goal.last_checked_at).to be >= before
    end
  end

  describe '#stalled?' do
    it 'returns false with fewer than 3 history entries' do
      goal.check_progress!(new_progress: 0.05, effort: 0.1)
      goal.check_progress!(new_progress: 0.08, effort: 0.1)
      expect(goal.stalled?).to be false
    end

    it 'returns true when last 3 deltas are all below STALL_THRESHOLD' do
      goal.check_progress!(new_progress: 0.01, effort: 0.1)
      goal.check_progress!(new_progress: 0.02, effort: 0.1)
      goal.check_progress!(new_progress: 0.03, effort: 0.1)
      expect(goal.stalled?).to be true
    end

    it 'returns false when any recent delta exceeds STALL_THRESHOLD' do
      goal.check_progress!(new_progress: 0.01, effort: 0.1)
      goal.check_progress!(new_progress: 0.02, effort: 0.1)
      goal.check_progress!(new_progress: 0.5, effort: 0.1)
      expect(goal.stalled?).to be false
    end

    it 'uses only the last 3 entries regardless of history length' do
      5.times { goal.check_progress!(new_progress: 0.5, effort: 0.1) }
      goal.check_progress!(new_progress: 0.51, effort: 0.1)
      goal.check_progress!(new_progress: 0.52, effort: 0.1)
      goal.check_progress!(new_progress: 0.53, effort: 0.1)
      expect(goal.stalled?).to be true
    end
  end

  describe '#sunk_cost_resistance' do
    it 'is 0 when investment is 0' do
      expect(goal.sunk_cost_resistance).to eq(0.0)
    end

    it 'approaches 1 as investment grows' do
      goal.check_progress!(new_progress: 0.1, effort: 1000.0)
      expect(goal.sunk_cost_resistance).to be > 0.99
    end

    it 'is 0.5 when investment is 1.0' do
      goal.check_progress!(new_progress: 0.1, effort: 1.0)
      expect(goal.sunk_cost_resistance).to be_within(0.001).of(0.5)
    end

    it 'exhibits diminishing returns — doubling investment gives less than double resistance' do
      g1 = described_class.new(label: 'A', domain: 'd')
      g2 = described_class.new(label: 'B', domain: 'd')
      g1.check_progress!(new_progress: 0.1, effort: 1.0)
      g2.check_progress!(new_progress: 0.1, effort: 2.0)
      gain1 = g1.sunk_cost_resistance
      gain2 = g2.sunk_cost_resistance - g1.sunk_cost_resistance
      expect(gain2).to be < gain1
    end
  end

  describe '#opportunity_cost_estimate' do
    it 'is 1.0 when progress is 0' do
      expect(goal.opportunity_cost_estimate).to eq(1.0)
    end

    it 'is 0.0 when progress is 1.0' do
      goal.check_progress!(new_progress: 1.0, effort: 0.1)
      expect(goal.opportunity_cost_estimate).to eq(0.0)
    end

    it 'decreases as progress increases' do
      goal.check_progress!(new_progress: 0.3, effort: 0.1)
      oc1 = goal.opportunity_cost_estimate
      goal.check_progress!(new_progress: 0.7, effort: 0.1)
      oc2 = goal.opportunity_cost_estimate
      expect(oc2).to be < oc1
    end
  end

  describe '#recent_progress_rate' do
    it 'is 0.0 with no history' do
      expect(goal.recent_progress_rate).to eq(0.0)
    end

    it 'averages last 3 deltas' do
      goal.check_progress!(new_progress: 0.2, effort: 0.1)
      goal.check_progress!(new_progress: 0.4, effort: 0.1)
      goal.check_progress!(new_progress: 0.6, effort: 0.1)
      expect(goal.recent_progress_rate).to be_within(0.001).of(0.2)
    end

    it 'uses only last 3 entries when more exist' do
      5.times { |i| goal.check_progress!(new_progress: (i + 1) * 0.1, effort: 0.1) }
      expect(goal.recent_progress_rate).to be_within(0.001).of(0.1)
    end
  end

  describe '#disengagement_score' do
    it 'is between 0 and 1' do
      expect(goal.disengagement_score).to be_between(0.0, 1.0)
    end

    it 'is higher for a stalled goal with no investment' do
      goal.check_progress!(new_progress: 0.01, effort: 0.0)
      goal.check_progress!(new_progress: 0.02, effort: 0.0)
      goal.check_progress!(new_progress: 0.03, effort: 0.0)
      expect(goal.disengagement_score).to be > 0.0
    end

    it 'is reduced by high investment (sunk cost bias)' do
      stalled = described_class.new(label: 'A', domain: 'd')
      invested = described_class.new(label: 'B', domain: 'd')

      3.times { stalled.check_progress!(new_progress: 0.01, effort: 0.0) }
      3.times { invested.check_progress!(new_progress: 0.01, effort: 1000.0) }

      expect(invested.disengagement_score).to be < stalled.disengagement_score
    end

    it 'is higher for low-progress goals (higher opportunity cost)' do
      low  = described_class.new(label: 'A', domain: 'd')
      high = described_class.new(label: 'B', domain: 'd')

      low.check_progress!(new_progress: 0.05, effort: 0.1)
      high.check_progress!(new_progress: 0.8, effort: 0.1)

      expect(low.disengagement_score).to be > high.disengagement_score
    end
  end

  describe '#recommend_disengage?' do
    it 'returns false when not stalled' do
      3.times { |i| goal.check_progress!(new_progress: (i + 1) * 0.2, effort: 0.1) }
      expect(goal.recommend_disengage?).to be false
    end

    it 'returns true when stalled and disengagement score exceeds 0.6' do
      3.times { goal.check_progress!(new_progress: 0.01, effort: 0.0) }
      next unless goal.disengagement_score > 0.6

      expect(goal.recommend_disengage?).to be true
    end

    it 'returns false when stalled but high investment suppresses score below 0.6' do
      3.times { goal.check_progress!(new_progress: 0.01, effort: 1000.0) }
      expect(goal.recommend_disengage?).to be false if goal.disengagement_score <= 0.6
    end
  end

  describe '#disengage!' do
    it 'sets state to :disengaged' do
      goal.disengage!(reason: :sunk_cost)
      expect(goal.state).to eq(:disengaged)
    end

    it 'records the reason' do
      goal.disengage!(reason: :low_progress)
      expect(goal.disengage_reason).to eq(:low_progress)
    end
  end

  describe '#to_h' do
    it 'returns a complete hash with all expected keys' do
      h = goal.to_h
      expect(h).to include(
        :id, :label, :domain, :state, :state_label, :progress, :investment,
        :stalled, :recommend_disengage, :disengagement_score, :sunk_cost_resistance,
        :opportunity_cost, :recent_progress_rate, :history_size, :disengage_reason,
        :created_at, :last_checked_at
      )
    end

    it 'includes correct label' do
      expect(goal.to_h[:label]).to eq('Learn Ruby')
    end

    it 'includes state_label from STATE_LABELS' do
      expect(goal.to_h[:state_label]).to eq(:pursuing)
    end

    it 'reflects disengagement after disengage!' do
      goal.disengage!(reason: :opportunity_cost)
      h = goal.to_h
      expect(h[:state]).to eq(:disengaged)
      expect(h[:state_label]).to eq(:released)
      expect(h[:disengage_reason]).to eq(:opportunity_cost)
    end

    it 'rounds numeric values to 4 decimal places' do
      goal.check_progress!(new_progress: 0.333_333, effort: 0.1)
      h = goal.to_h
      expect(h[:progress].to_s.split('.').last.length).to be <= 4
    end
  end
end
