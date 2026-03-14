# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveScaffolding
      module Runners
        module CognitiveScaffolding
          include Legion::Extensions::Helpers::Lex if Legion::Extensions.const_defined?(:Helpers) &&
                                                      Legion::Extensions::Helpers.const_defined?(:Lex)

          def create_scaffold(skill_name:, domain:, competence: nil, **)
            comp = competence || Helpers::Constants::DEFAULT_COMPETENCE
            scaffold = engine.create_scaffold(skill_name: skill_name, domain: domain, competence: comp)
            Legion::Logging.debug "[cognitive_scaffolding] created: skill=#{skill_name} domain=#{domain} " \
                                  "competence=#{scaffold.competence.round(2)} zone=#{scaffold.current_zone}"
            { success: true, scaffold: scaffold.to_h }
          end

          def attempt_scaffolded_task(scaffold_id:, difficulty:, success:, **)
            scaffold = engine.attempt_scaffolded_task(scaffold_id: scaffold_id, difficulty: difficulty, success: success)
            unless scaffold
              Legion::Logging.debug "[cognitive_scaffolding] attempt: scaffold_id=#{scaffold_id} not found"
              return { success: false, reason: :not_found, scaffold_id: scaffold_id }
            end

            Legion::Logging.debug "[cognitive_scaffolding] attempt: skill=#{scaffold.skill_name} " \
                                  "difficulty=#{difficulty.round(2)} success=#{success} " \
                                  "competence=#{scaffold.competence.round(2)} zone=#{scaffold.current_zone}"
            { success: true, scaffold: scaffold.to_h }
          end

          def recommend_scaffolded_task(scaffold_id:, **)
            recommendation = engine.recommend_task(scaffold_id: scaffold_id)
            unless recommendation
              Legion::Logging.debug "[cognitive_scaffolding] recommend: scaffold_id=#{scaffold_id} not found"
              return { success: false, reason: :not_found, scaffold_id: scaffold_id }
            end

            Legion::Logging.debug "[cognitive_scaffolding] recommend: difficulty=#{recommendation[:difficulty].round(2)} " \
                                  "support=#{recommendation[:support_level]} zone=#{recommendation[:zone]}"
            { success: true, recommendation: recommendation }
          end

          def mastered_scaffolded_skills(**)
            skills = engine.mastered_skills
            Legion::Logging.debug "[cognitive_scaffolding] mastered: count=#{skills.size}"
            { success: true, skills: skills.map(&:to_h), count: skills.size }
          end

          def zpd_skills(**)
            skills = engine.zpd_skills
            Legion::Logging.debug "[cognitive_scaffolding] zpd: count=#{skills.size}"
            { success: true, skills: skills.map(&:to_h), count: skills.size }
          end

          def domain_scaffolds(domain:, **)
            scaffolds = engine.by_domain(domain: domain)
            Legion::Logging.debug "[cognitive_scaffolding] domain: domain=#{domain} count=#{scaffolds.size}"
            { success: true, domain: domain, scaffolds: scaffolds.map(&:to_h), count: scaffolds.size }
          end

          def adjust_scaffold_support(scaffold_id:, direction:, **)
            scaffold = engine.adjust_support(scaffold_id: scaffold_id, direction: direction)
            unless scaffold
              Legion::Logging.debug "[cognitive_scaffolding] adjust_support: scaffold_id=#{scaffold_id} not found"
              return { success: false, reason: :not_found, scaffold_id: scaffold_id }
            end

            Legion::Logging.debug "[cognitive_scaffolding] adjust_support: skill=#{scaffold.skill_name} " \
                                  "direction=#{direction} support=#{scaffold.support_level}"
            { success: true, scaffold: scaffold.to_h }
          end

          def overall_scaffolded_competence(**)
            overall = engine.overall_competence
            Legion::Logging.debug "[cognitive_scaffolding] overall_competence: #{overall.round(3)}"
            { success: true, overall_competence: overall.round(4) }
          end

          def update_cognitive_scaffolding(**)
            count = engine.decay_all
            overall = engine.overall_competence
            Legion::Logging.debug "[cognitive_scaffolding] decay: scaffolds=#{count} overall=#{overall.round(3)}"
            { success: true, action: :decay, scaffold_count: count, overall_competence: overall.round(4) }
          end

          def cognitive_scaffolding_stats(**)
            stats = engine.to_h
            Legion::Logging.debug "[cognitive_scaffolding] stats: total=#{stats[:total_scaffolds]} " \
                                  "mastered=#{stats[:mastered_count]} zpd=#{stats[:zpd_count]}"
            { success: true, stats: stats }
          end

          private

          def engine
            @engine ||= Helpers::ScaffoldingEngine.new
          end
        end
      end
    end
  end
end
