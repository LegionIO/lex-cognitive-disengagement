# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::CognitiveDisengagement::Helpers::Constants do
  let(:mod) { described_class }

  describe 'GOAL_STATES' do
    it 'is frozen' do
      expect(mod::GOAL_STATES).to be_frozen
    end

    it 'contains expected states' do
      expect(mod::GOAL_STATES).to include(:active, :monitoring, :stalled, :disengaging, :disengaged)
    end

    it 'has 5 states' do
      expect(mod::GOAL_STATES.size).to eq(5)
    end
  end

  describe 'DISENGAGE_REASONS' do
    it 'is frozen' do
      expect(mod::DISENGAGE_REASONS).to be_frozen
    end

    it 'contains all expected reasons' do
      expect(mod::DISENGAGE_REASONS).to include(
        :sunk_cost, :low_progress, :opportunity_cost,
        :goal_conflict, :resource_exhaustion, :external_block
      )
    end
  end

  describe 'STATE_LABELS' do
    it 'is frozen' do
      expect(mod::STATE_LABELS).to be_frozen
    end

    it 'maps all GOAL_STATES' do
      mod::GOAL_STATES.each do |state|
        expect(mod::STATE_LABELS).to have_key(state)
      end
    end

    it 'maps :active to :pursuing' do
      expect(mod::STATE_LABELS[:active]).to eq(:pursuing)
    end

    it 'maps :disengaged to :released' do
      expect(mod::STATE_LABELS[:disengaged]).to eq(:released)
    end
  end

  describe 'numeric constants' do
    it 'MAX_GOALS is 100' do
      expect(mod::MAX_GOALS).to eq(100)
    end

    it 'MAX_HISTORY is 300' do
      expect(mod::MAX_HISTORY).to eq(300)
    end

    it 'STALL_THRESHOLD is 0.1' do
      expect(mod::STALL_THRESHOLD).to eq(0.1)
    end

    it 'DISENGAGE_THRESHOLD is 0.05' do
      expect(mod::DISENGAGE_THRESHOLD).to eq(0.05)
    end

    it 'weights sum to 1.0' do
      total = mod::SUNK_COST_WEIGHT + mod::OPPORTUNITY_COST_WEIGHT + mod::PROGRESS_WEIGHT
      expect(total).to be_within(0.001).of(1.0)
    end

    it 'DECAY_RATE is 0.02' do
      expect(mod::DECAY_RATE).to eq(0.02)
    end
  end
end
