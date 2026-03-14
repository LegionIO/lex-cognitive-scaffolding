# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveScaffolding
      module Helpers
        class ScaffoldingEngine
          include Constants

          attr_reader :scaffolds

          def initialize
            @scaffolds = {}
          end

          def create_scaffold(skill_name:, domain:, competence: nil)
            trim_scaffolds if @scaffolds.size >= MAX_SCAFFOLDS
            comp = competence.nil? ? DEFAULT_COMPETENCE : competence
            scaffold = Scaffold.new(skill_name: skill_name, domain: domain, competence: comp)
            @scaffolds[scaffold.id] = scaffold
            scaffold
          end

          def attempt_scaffolded_task(scaffold_id:, difficulty:, success:)
            scaffold = find(scaffold_id)
            return nil unless scaffold

            scaffold.attempt_task(difficulty: difficulty, success: success)
            scaffold
          end

          def recommend_task(scaffold_id:)
            scaffold = find(scaffold_id)
            return nil unless scaffold

            {
              difficulty:    scaffold.recommended_difficulty,
              support_level: scaffold.support_level,
              zone:          scaffold.current_zone
            }
          end

          def mastered_skills
            @scaffolds.values.select(&:mastered?)
          end

          def zpd_skills
            @scaffolds.values.select(&:in_zpd?)
          end

          def by_domain(domain:)
            @scaffolds.values.select { |s| s.domain == domain }
          end

          def adjust_support(scaffold_id:, direction:)
            scaffold = find(scaffold_id)
            return nil unless scaffold

            case direction
            when :increase then scaffold.increase_support!
            when :decrease then scaffold.fade_support!
            end

            scaffold
          end

          def overall_competence
            return DEFAULT_COMPETENCE if @scaffolds.empty?

            @scaffolds.values.sum(&:competence) / @scaffolds.size
          end

          def decay_all
            @scaffolds.each_value do |scaffold|
              next if scaffold.mastered?

              decayed = (scaffold.competence - DECAY_RATE).clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
              scaffold.instance_variable_set(:@competence, decayed)
            end
            @scaffolds.size
          end

          def to_h
            {
              total_scaffolds:    @scaffolds.size,
              mastered_count:     mastered_skills.size,
              zpd_count:          zpd_skills.size,
              overall_competence: overall_competence.round(4)
            }
          end

          private

          def find(scaffold_id)
            @scaffolds[scaffold_id]
          end

          def trim_scaffolds
            mastered = mastered_skills.sort_by(&:last_practiced_at)
            candidates = mastered.any? ? mastered : @scaffolds.values.sort_by(&:last_practiced_at)
            remove = candidates.first
            @scaffolds.delete(remove.id) if remove
          end
        end
      end
    end
  end
end
