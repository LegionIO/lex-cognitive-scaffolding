# frozen_string_literal: true

RSpec.describe Legion::Extensions::CognitiveScaffolding::Helpers::Constants do
  let(:constants) { described_class }

  it 'defines SUPPORT_LEVELS as frozen array of symbols' do
    expect(constants::SUPPORT_LEVELS).to eq(%i[full guided prompted independent])
    expect(constants::SUPPORT_LEVELS).to be_frozen
  end

  it 'defines ZONE_LABELS covering 0..1 range' do
    all_covered = [0.0, 0.1, 0.3, 0.5, 0.85, 1.0].all? do |val|
      constants::ZONE_LABELS.any? { |range, _| range.cover?(val) }
    end
    expect(all_covered).to be true
  end

  it 'defines competence bounds' do
    expect(constants::COMPETENCE_FLOOR).to eq(0.0)
    expect(constants::COMPETENCE_CEILING).to eq(1.0)
  end

  it 'defines ZPD bounds within 0..1' do
    expect(constants::ZPD_LOWER).to be >= 0.0
    expect(constants::ZPD_UPPER).to be <= 1.0
    expect(constants::ZPD_LOWER).to be < constants::ZPD_UPPER
  end

  it 'LEARNING_GAIN > FAILURE_SETBACK' do
    expect(constants::LEARNING_GAIN).to be > constants::FAILURE_SETBACK
  end

  it 'MASTERY_THRESHOLD is above ZPD_UPPER' do
    expect(constants::MASTERY_THRESHOLD).to be >= constants::ZPD_UPPER
  end
end
