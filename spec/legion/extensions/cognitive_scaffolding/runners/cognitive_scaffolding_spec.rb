# frozen_string_literal: true

require 'legion/extensions/cognitive_scaffolding/client'

RSpec.describe Legion::Extensions::CognitiveScaffolding::Runners::CognitiveScaffolding do
  let(:client) { Legion::Extensions::CognitiveScaffolding::Client.new }
  let(:constants) { Legion::Extensions::CognitiveScaffolding::Helpers::Constants }

  def create_scaffold(skill: 'algebra', domain: :math, competence: nil)
    result = if competence
               client.create_scaffold(skill_name: skill, domain: domain, competence: competence)
             else
               client.create_scaffold(skill_name: skill, domain: domain)
             end
    result[:scaffold][:id]
  end

  describe '#create_scaffold' do
    it 'returns success with scaffold data' do
      result = client.create_scaffold(skill_name: 'reading', domain: :language)
      expect(result[:success]).to be true
      expect(result[:scaffold]).to include(:id, :skill_name, :domain, :competence)
    end

    it 'uses DEFAULT_COMPETENCE by default' do
      result = client.create_scaffold(skill_name: 'reading', domain: :language)
      expect(result[:scaffold][:competence]).to eq(constants::DEFAULT_COMPETENCE)
    end

    it 'accepts custom competence' do
      result = client.create_scaffold(skill_name: 'x', domain: :test, competence: 0.6)
      expect(result[:scaffold][:competence]).to eq(0.6)
    end
  end

  describe '#attempt_scaffolded_task' do
    it 'returns success for valid scaffold' do
      sid = create_scaffold
      result = client.attempt_scaffolded_task(scaffold_id: sid, difficulty: 0.5, success: true)
      expect(result[:success]).to be true
      expect(result[:scaffold]).to include(:competence)
    end

    it 'returns failure for unknown scaffold_id' do
      result = client.attempt_scaffolded_task(scaffold_id: 'nonexistent', difficulty: 0.5, success: true)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end

    it 'increases competence on success' do
      result_create = client.create_scaffold(skill_name: 'y', domain: :test)
      sid = result_create[:scaffold][:id]
      before = result_create[:scaffold][:competence]
      attempt = client.attempt_scaffolded_task(scaffold_id: sid, difficulty: 0.5, success: true)
      expect(attempt[:scaffold][:competence]).to be > before
    end

    it 'decreases competence on failure' do
      result_create = client.create_scaffold(skill_name: 'z', domain: :test)
      sid = result_create[:scaffold][:id]
      before = result_create[:scaffold][:competence]
      attempt = client.attempt_scaffolded_task(scaffold_id: sid, difficulty: 0.5, success: false)
      expect(attempt[:scaffold][:competence]).to be < before
    end
  end

  describe '#recommend_scaffolded_task' do
    it 'returns recommendation for valid scaffold' do
      sid = create_scaffold
      result = client.recommend_scaffolded_task(scaffold_id: sid)
      expect(result[:success]).to be true
      expect(result[:recommendation]).to include(:difficulty, :support_level, :zone)
    end

    it 'returns failure for unknown id' do
      result = client.recommend_scaffolded_task(scaffold_id: 'bad')
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#mastered_scaffolded_skills' do
    it 'returns empty when none mastered' do
      create_scaffold
      result = client.mastered_scaffolded_skills
      expect(result[:success]).to be true
      expect(result[:count]).to eq(0)
    end

    it 'returns mastered scaffolds' do
      create_scaffold(competence: constants::MASTERY_THRESHOLD)
      result = client.mastered_scaffolded_skills
      expect(result[:count]).to eq(1)
    end
  end

  describe '#zpd_skills' do
    it 'returns scaffolds in ZPD' do
      create_scaffold
      result = client.zpd_skills
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
    end
  end

  describe '#domain_scaffolds' do
    it 'filters scaffolds by domain' do
      create_scaffold(domain: :math)
      create_scaffold(domain: :language)
      result = client.domain_scaffolds(domain: :math)
      expect(result[:success]).to be true
      expect(result[:count]).to eq(1)
      expect(result[:domain]).to eq(:math)
    end
  end

  describe '#adjust_scaffold_support' do
    it 'adjusts support direction increase' do
      sid = create_scaffold
      result = client.adjust_scaffold_support(scaffold_id: sid, direction: :increase)
      expect(result[:success]).to be true
    end

    it 'returns failure for unknown id' do
      result = client.adjust_scaffold_support(scaffold_id: 'bad', direction: :increase)
      expect(result[:success]).to be false
      expect(result[:reason]).to eq(:not_found)
    end
  end

  describe '#overall_scaffolded_competence' do
    it 'returns success with a float' do
      result = client.overall_scaffolded_competence
      expect(result[:success]).to be true
      expect(result[:overall_competence]).to be_a(Float)
    end

    it 'reflects created scaffolds' do
      client.create_scaffold(skill_name: 'a', domain: :test, competence: 0.8)
      result = client.overall_scaffolded_competence
      expect(result[:overall_competence]).to be > constants::DEFAULT_COMPETENCE
    end
  end

  describe '#update_cognitive_scaffolding' do
    it 'runs decay and returns stats' do
      create_scaffold
      result = client.update_cognitive_scaffolding
      expect(result[:success]).to be true
      expect(result[:action]).to eq(:decay)
      expect(result[:scaffold_count]).to eq(1)
    end
  end

  describe '#cognitive_scaffolding_stats' do
    it 'returns stats hash' do
      create_scaffold
      result = client.cognitive_scaffolding_stats
      expect(result[:success]).to be true
      expect(result[:stats]).to include(:total_scaffolds, :mastered_count, :zpd_count, :overall_competence)
    end
  end
end
