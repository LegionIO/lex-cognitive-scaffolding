# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveScaffolding::Helpers::Scaffold do
  let(:constants) { Legion::Extensions::CognitiveScaffolding::Helpers::Constants }

  subject(:scaffold) { described_class.new(skill_name: 'algebra', domain: :math) }

  describe '#initialize' do
    it 'assigns an id' do
      expect(scaffold.id).to be_a(String)
      expect(scaffold.id).not_to be_empty
    end

    it 'sets default competence' do
      expect(scaffold.competence).to eq(constants::DEFAULT_COMPETENCE)
    end

    it 'sets skill_name and domain' do
      expect(scaffold.skill_name).to eq('algebra')
      expect(scaffold.domain).to eq(:math)
    end

    it 'starts with no practice' do
      expect(scaffold.practice_count).to eq(0)
      expect(scaffold.task_history).to be_empty
    end

    it 'clamps competence to valid range' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: 2.5)
      expect(s.competence).to eq(1.0)
    end
  end

  describe '#current_zone' do
    it 'returns :zpd for default competence' do
      expect(scaffold.current_zone).to eq(:zpd)
    end

    it 'returns :mastered when competence >= MASTERY_THRESHOLD' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: constants::MASTERY_THRESHOLD)
      expect(s.current_zone).to eq(:mastered)
    end

    it 'returns :beyond_reach for low competence' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: 0.1)
      expect(s.current_zone).to eq(:beyond_reach)
    end
  end

  describe '#mastered?' do
    it 'returns false at default competence' do
      expect(scaffold.mastered?).to be false
    end

    it 'returns true at mastery threshold' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: constants::MASTERY_THRESHOLD)
      expect(s.mastered?).to be true
    end
  end

  describe '#in_zpd?' do
    it 'returns true at default competence' do
      expect(scaffold.in_zpd?).to be true
    end

    it 'returns false below ZPD_LOWER' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: 0.1)
      expect(s.in_zpd?).to be false
    end

    it 'returns false at or above ZPD_UPPER' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: constants::ZPD_UPPER)
      expect(s.in_zpd?).to be false
    end
  end

  describe '#recommended_difficulty' do
    it 'returns a value above current competence' do
      expect(scaffold.recommended_difficulty).to be >= scaffold.competence
    end

    it 'is within valid competence bounds' do
      expect(scaffold.recommended_difficulty).to be_between(constants::COMPETENCE_FLOOR, constants::COMPETENCE_CEILING)
    end
  end

  describe '#attempt_task' do
    context 'success in ZPD' do
      it 'increases competence by LEARNING_GAIN' do
        before = scaffold.competence
        difficulty = 0.5
        scaffold.attempt_task(difficulty: difficulty, success: true)
        expect(scaffold.competence).to be > before
      end
    end

    context 'success below ZPD' do
      it 'increases competence by half LEARNING_GAIN' do
        s = described_class.new(skill_name: 'x', domain: :test, competence: 0.15)
        before = s.competence
        s.attempt_task(difficulty: 0.1, success: true)
        expect(s.competence - before).to be_within(0.001).of(constants::LEARNING_GAIN / 2.0)
      end
    end

    context 'failure' do
      it 'decreases competence by FAILURE_SETBACK' do
        before = scaffold.competence
        scaffold.attempt_task(difficulty: 0.5, success: false)
        expect(scaffold.competence).to eq((before - constants::FAILURE_SETBACK).clamp(0.0, 1.0))
      end
    end

    it 'increments practice_count' do
      scaffold.attempt_task(difficulty: 0.5, success: true)
      expect(scaffold.practice_count).to eq(1)
    end

    it 'records task in history' do
      scaffold.attempt_task(difficulty: 0.5, success: true)
      expect(scaffold.task_history.size).to eq(1)
      expect(scaffold.task_history.last[:success]).to be true
    end

    it 'clamps competence at COMPETENCE_CEILING' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: 0.99)
      10.times { s.attempt_task(difficulty: 0.5, success: true) }
      expect(s.competence).to be <= constants::COMPETENCE_CEILING
    end

    it 'clamps competence at COMPETENCE_FLOOR' do
      s = described_class.new(skill_name: 'x', domain: :test, competence: 0.01)
      10.times { s.attempt_task(difficulty: 0.5, success: false) }
      expect(s.competence).to be >= constants::COMPETENCE_FLOOR
    end
  end

  describe '#fade_support!' do
    it 'moves toward independent' do
      scaffold.instance_variable_set(:@support_level, :full)
      scaffold.fade_support!
      expect(scaffold.support_level).to eq(:guided)
    end

    it 'does not go beyond independent' do
      scaffold.instance_variable_set(:@support_level, :independent)
      scaffold.fade_support!
      expect(scaffold.support_level).to eq(:independent)
    end
  end

  describe '#increase_support!' do
    it 'moves toward full' do
      scaffold.instance_variable_set(:@support_level, :independent)
      scaffold.increase_support!
      expect(scaffold.support_level).to eq(:prompted)
    end

    it 'does not go beyond full' do
      scaffold.instance_variable_set(:@support_level, :full)
      scaffold.increase_support!
      expect(scaffold.support_level).to eq(:full)
    end
  end

  describe '#to_h' do
    it 'contains expected keys' do
      h = scaffold.to_h
      expect(h).to have_key(:id)
      expect(h).to have_key(:skill_name)
      expect(h).to have_key(:domain)
      expect(h).to have_key(:competence)
      expect(h).to have_key(:support_level)
      expect(h).to have_key(:current_zone)
      expect(h).to have_key(:practice_count)
      expect(h).to have_key(:mastered)
      expect(h).to have_key(:in_zpd)
    end
  end

  describe 'task history cap' do
    it 'does not exceed MAX_HISTORY' do
      (constants::MAX_HISTORY + 5).times { scaffold.attempt_task(difficulty: 0.5, success: true) }
      expect(scaffold.task_history.size).to eq(constants::MAX_HISTORY)
    end
  end
end
