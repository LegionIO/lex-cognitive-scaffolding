# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveScaffolding::Helpers::ScaffoldingEngine do
  let(:engine) { described_class.new }
  let(:constants) { Legion::Extensions::CognitiveScaffolding::Helpers::Constants }

  def make_scaffold(skill: 'reading', domain: :language, competence: nil)
    engine.create_scaffold(skill_name: skill, domain: domain, competence: competence)
  end

  describe '#create_scaffold' do
    it 'returns a Scaffold' do
      scaffold = make_scaffold
      expect(scaffold).to be_a(Legion::Extensions::CognitiveScaffolding::Helpers::Scaffold)
    end

    it 'stores the scaffold' do
      scaffold = make_scaffold
      expect(engine.scaffolds[scaffold.id]).to eq(scaffold)
    end

    it 'uses DEFAULT_COMPETENCE when not provided' do
      scaffold = make_scaffold
      expect(scaffold.competence).to eq(constants::DEFAULT_COMPETENCE)
    end

    it 'accepts custom competence' do
      scaffold = make_scaffold(competence: 0.7)
      expect(scaffold.competence).to eq(0.7)
    end
  end

  describe '#attempt_scaffolded_task' do
    it 'returns the scaffold after attempt' do
      scaffold = make_scaffold
      result = engine.attempt_scaffolded_task(scaffold_id: scaffold.id, difficulty: 0.5, success: true)
      expect(result).to be_a(Legion::Extensions::CognitiveScaffolding::Helpers::Scaffold)
    end

    it 'returns nil for unknown scaffold_id' do
      result = engine.attempt_scaffolded_task(scaffold_id: 'nonexistent', difficulty: 0.5, success: true)
      expect(result).to be_nil
    end

    it 'updates competence on attempt' do
      scaffold = make_scaffold
      before = scaffold.competence
      engine.attempt_scaffolded_task(scaffold_id: scaffold.id, difficulty: 0.5, success: true)
      expect(scaffold.competence).not_to eq(before)
    end
  end

  describe '#recommend_task' do
    it 'returns difficulty, support_level, and zone' do
      scaffold = make_scaffold
      rec = engine.recommend_task(scaffold_id: scaffold.id)
      expect(rec).to include(:difficulty, :support_level, :zone)
    end

    it 'returns nil for unknown id' do
      expect(engine.recommend_task(scaffold_id: 'unknown')).to be_nil
    end
  end

  describe '#mastered_skills' do
    it 'returns empty when nothing mastered' do
      make_scaffold
      expect(engine.mastered_skills).to be_empty
    end

    it 'returns mastered scaffolds' do
      make_scaffold(competence: constants::MASTERY_THRESHOLD)
      expect(engine.mastered_skills.size).to eq(1)
    end
  end

  describe '#zpd_skills' do
    it 'returns scaffolds in ZPD' do
      make_scaffold
      expect(engine.zpd_skills.size).to eq(1)
    end

    it 'does not include mastered scaffolds' do
      make_scaffold(competence: constants::MASTERY_THRESHOLD)
      expect(engine.zpd_skills).to be_empty
    end
  end

  describe '#by_domain' do
    it 'filters by domain' do
      make_scaffold(domain: :math)
      make_scaffold(domain: :language)
      expect(engine.by_domain(domain: :math).size).to eq(1)
    end
  end

  describe '#adjust_support' do
    it 'increases support level' do
      scaffold = make_scaffold
      scaffold.instance_variable_set(:@support_level, :independent)
      engine.adjust_support(scaffold_id: scaffold.id, direction: :increase)
      expect(scaffold.support_level).to eq(:prompted)
    end

    it 'decreases (fades) support level' do
      scaffold = make_scaffold
      scaffold.instance_variable_set(:@support_level, :full)
      engine.adjust_support(scaffold_id: scaffold.id, direction: :decrease)
      expect(scaffold.support_level).to eq(:guided)
    end

    it 'returns nil for unknown id' do
      expect(engine.adjust_support(scaffold_id: 'x', direction: :increase)).to be_nil
    end
  end

  describe '#overall_competence' do
    it 'returns DEFAULT_COMPETENCE with no scaffolds' do
      expect(engine.overall_competence).to eq(constants::DEFAULT_COMPETENCE)
    end

    it 'averages competences' do
      engine.create_scaffold(skill_name: 'a', domain: :test, competence: 0.4)
      engine.create_scaffold(skill_name: 'b', domain: :test, competence: 0.6)
      expect(engine.overall_competence).to be_within(0.001).of(0.5)
    end
  end

  describe '#decay_all' do
    it 'returns the scaffold count' do
      2.times { |i| make_scaffold(skill: "s#{i}") }
      expect(engine.decay_all).to eq(2)
    end

    it 'reduces competence on non-mastered scaffolds' do
      scaffold = make_scaffold
      before = scaffold.competence
      engine.decay_all
      expect(scaffold.competence).to be < before
    end

    it 'does not decay mastered scaffolds' do
      scaffold = make_scaffold(competence: constants::MASTERY_THRESHOLD)
      before = scaffold.competence
      engine.decay_all
      expect(scaffold.competence).to eq(before)
    end
  end

  describe '#to_h' do
    it 'contains expected stat keys' do
      h = engine.to_h
      expect(h).to have_key(:total_scaffolds)
      expect(h).to have_key(:mastered_count)
      expect(h).to have_key(:zpd_count)
      expect(h).to have_key(:overall_competence)
    end
  end
end
