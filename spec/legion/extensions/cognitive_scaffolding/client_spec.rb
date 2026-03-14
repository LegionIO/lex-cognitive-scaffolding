# frozen_string_literal: true

require 'legion/extensions/cognitive_scaffolding/client'

RSpec.describe Legion::Extensions::CognitiveScaffolding::Client do
  let(:client) { described_class.new }

  it 'responds to all runner methods' do
    expect(client).to respond_to(:create_scaffold)
    expect(client).to respond_to(:attempt_scaffolded_task)
    expect(client).to respond_to(:recommend_scaffolded_task)
    expect(client).to respond_to(:mastered_scaffolded_skills)
    expect(client).to respond_to(:zpd_skills)
    expect(client).to respond_to(:domain_scaffolds)
    expect(client).to respond_to(:adjust_scaffold_support)
    expect(client).to respond_to(:overall_scaffolded_competence)
    expect(client).to respond_to(:update_cognitive_scaffolding)
    expect(client).to respond_to(:cognitive_scaffolding_stats)
  end
end
