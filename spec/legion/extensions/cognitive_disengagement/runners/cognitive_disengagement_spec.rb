# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Legion::Extensions::CognitiveDisengagement::Runners::CognitiveDisengagement do
  let(:client) { Legion::Extensions::CognitiveDisengagement::Client.new }

  describe '#create_disengagement_goal' do
    it 'returns success: true' do
      result = client.create_disengagement_goal(label: 'Write book', domain: 'creative')
      expect(result[:success]).to be true
    end

    it 'includes goal hash' do
      result = client.create_disengagement_goal(label: 'Write book', domain: 'creative')
      expect(result[:goal]).to include(:id, :label, :domain, :state)
    end

    it 'reflects the given label and domain' do
      result = client.create_disengagement_goal(label: 'Ship product', domain: 'work')
      expect(result[:goal][:label]).to eq('Ship product')
      expect(result[:goal][:domain]).to eq('work')
    end
  end

  describe '#check_goal_progress' do
    let(:goal_id) do
      client.create_disengagement_goal(label: 'Finish thesis', domain: 'academic')[:goal][:id]
    end

    it 'returns success: true for a valid goal' do
      result = client.check_goal_progress(goal_id: goal_id, new_progress: 0.3, effort: 0.5)
      expect(result[:success]).to be true
    end

    it 'returns the progress delta' do
      result = client.check_goal_progress(goal_id: goal_id, new_progress: 0.3, effort: 0.5)
      expect(result[:delta]).to be_a(Float)
    end

    it 'returns success: false for unknown goal_id' do
      result = client.check_goal_progress(goal_id: 'bad', new_progress: 0.1, effort: 0.1)
      expect(result[:success]).to be false
      expect(result[:error]).to be_a(String)
    end

    it 'uses default effort of 0.1' do
      result = client.check_goal_progress(goal_id: goal_id, new_progress: 0.2)
      expect(result[:success]).to be true
    end
  end

  describe '#assess_goal_disengagement' do
    let(:goal_id) do
      client.create_disengagement_goal(label: 'Learn piano', domain: 'hobby')[:goal][:id]
    end

    it 'returns success: true' do
      result = client.assess_goal_disengagement(goal_id: goal_id)
      expect(result[:success]).to be true
    end

    it 'includes assessment hash' do
      result = client.assess_goal_disengagement(goal_id: goal_id)
      expect(result[:assessment]).to include(
        :id, :label, :domain, :stalled, :recommend_disengage, :disengagement_score
      )
    end

    it 'returns success: false for unknown goal' do
      result = client.assess_goal_disengagement(goal_id: 'missing')
      expect(result[:success]).to be false
    end
  end

  describe '#disengage_from_goal' do
    let(:goal_id) do
      client.create_disengagement_goal(label: 'Run marathon', domain: 'fitness')[:goal][:id]
    end

    it 'returns success: true' do
      result = client.disengage_from_goal(goal_id: goal_id, reason: :low_progress)
      expect(result[:success]).to be true
    end

    it 'transitions goal to :disengaged state' do
      result = client.disengage_from_goal(goal_id: goal_id, reason: :sunk_cost)
      expect(result[:goal][:state]).to eq(:disengaged)
    end

    it 'records the disengage reason' do
      result = client.disengage_from_goal(goal_id: goal_id, reason: :opportunity_cost)
      expect(result[:goal][:disengage_reason]).to eq(:opportunity_cost)
    end

    it 'returns success: false for unknown goal_id' do
      result = client.disengage_from_goal(goal_id: 'nope', reason: :sunk_cost)
      expect(result[:success]).to be false
    end
  end

  describe '#stalled_goals_report' do
    it 'returns success: true' do
      result = client.stalled_goals_report
      expect(result[:success]).to be true
    end

    it 'returns count and goals array' do
      result = client.stalled_goals_report
      expect(result).to include(:goals, :count)
      expect(result[:goals]).to be_an(Array)
    end

    it 'includes stalled goals after repeated low-progress checks' do
      id = client.create_disengagement_goal(label: 'Cold call', domain: 'sales')[:goal][:id]
      3.times { client.check_goal_progress(goal_id: id, new_progress: 0.01, effort: 0.1) }
      result = client.stalled_goals_report
      ids = result[:goals].map { |g| g[:id] }
      expect(ids).to include(id)
    end
  end

  describe '#active_goals_report' do
    it 'returns success: true' do
      expect(client.active_goals_report[:success]).to be true
    end

    it 'includes count of active goals' do
      client.create_disengagement_goal(label: 'A', domain: 'd')
      client.create_disengagement_goal(label: 'B', domain: 'd')
      expect(client.active_goals_report[:count]).to eq(2)
    end

    it 'decrements after disengagement' do
      id = client.create_disengagement_goal(label: 'X', domain: 'd')[:goal][:id]
      client.disengage_from_goal(goal_id: id, reason: :sunk_cost)
      expect(client.active_goals_report[:count]).to eq(0)
    end
  end

  describe '#most_invested_goals' do
    it 'returns success: true' do
      expect(client.most_invested_goals[:success]).to be true
    end

    it 'respects the limit parameter' do
      3.times { |i| client.create_disengagement_goal(label: "G#{i}", domain: 'd') }
      result = client.most_invested_goals(limit: 2)
      expect(result[:goals].size).to be <= 2
    end

    it 'sorts by investment descending' do
      id1 = client.create_disengagement_goal(label: 'High', domain: 'd')[:goal][:id]
      id2 = client.create_disengagement_goal(label: 'Low', domain: 'd')[:goal][:id]
      client.check_goal_progress(goal_id: id1, new_progress: 0.3, effort: 10.0)
      client.check_goal_progress(goal_id: id2, new_progress: 0.1, effort: 0.1)
      result = client.most_invested_goals(limit: 2)
      expect(result[:goals].first[:id]).to eq(id1)
    end
  end

  describe '#highest_disengage_candidates' do
    it 'returns success: true' do
      expect(client.highest_disengage_candidates[:success]).to be true
    end

    it 'respects the limit parameter' do
      4.times { |i| client.create_disengagement_goal(label: "G#{i}", domain: 'd') }
      result = client.highest_disengage_candidates(limit: 2)
      expect(result[:goals].size).to be <= 2
    end
  end

  describe '#update_cognitive_disengagement' do
    it 'returns success: true' do
      expect(client.update_cognitive_disengagement[:success]).to be true
    end

    it 'includes stats' do
      result = client.update_cognitive_disengagement
      expect(result[:stats]).to include(:total_goals, :active_goals)
    end

    it 'decays active goal progress' do
      id = client.create_disengagement_goal(label: 'Decay me', domain: 'test')[:goal][:id]
      client.check_goal_progress(goal_id: id, new_progress: 0.5, effort: 0.1)
      before_assessment = client.assess_goal_disengagement(goal_id: id)[:assessment][:progress]
      client.update_cognitive_disengagement
      after_assessment = client.assess_goal_disengagement(goal_id: id)[:assessment][:progress]
      expect(after_assessment).to be < before_assessment
    end
  end

  describe '#cognitive_disengagement_stats' do
    it 'returns success: true' do
      expect(client.cognitive_disengagement_stats[:success]).to be true
    end

    it 'includes stats hash' do
      result = client.cognitive_disengagement_stats
      expect(result[:stats]).to include(
        :total_goals, :active_goals, :stalled_goals, :disengaged_goals
      )
    end

    it 'tracks totals accurately across lifecycle' do
      id = client.create_disengagement_goal(label: 'Track me', domain: 'ops')[:goal][:id]
      expect(client.cognitive_disengagement_stats[:stats][:total_goals]).to eq(1)
      client.disengage_from_goal(goal_id: id, reason: :resource_exhaustion)
      stats = client.cognitive_disengagement_stats[:stats]
      expect(stats[:disengaged_goals]).to eq(1)
      expect(stats[:active_goals]).to eq(0)
    end
  end
end
