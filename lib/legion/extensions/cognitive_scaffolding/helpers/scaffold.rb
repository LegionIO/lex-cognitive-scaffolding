# frozen_string_literal: true

require 'securerandom'

module Legion
  module Extensions
    module CognitiveScaffolding
      module Helpers
        class Scaffold
          include Constants

          attr_reader :id, :skill_name, :domain, :competence, :support_level,
                      :task_history, :practice_count, :created_at, :last_practiced_at

          def initialize(skill_name:, domain:, competence: DEFAULT_COMPETENCE)
            @id               = SecureRandom.uuid
            @skill_name       = skill_name
            @domain           = domain
            @competence       = competence.to_f.clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
            @support_level    = initial_support_level
            @task_history     = []
            @practice_count   = 0
            @created_at       = Time.now.utc
            @last_practiced_at = nil
          end

          def attempt_task(difficulty:, success:)
            diff = difficulty.to_f.clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
            delta = compute_delta(difficulty: diff, success: success)
            @competence = (@competence + delta).clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
            @practice_count   += 1
            @last_practiced_at = Time.now.utc

            record_task(difficulty: diff, success: success)
            adjust_support(success)
            @competence
          end

          def current_zone
            ZONE_LABELS.each do |range, label|
              return label if range.cover?(@competence)
            end
            :beyond_reach
          end

          def recommended_difficulty
            (@competence + ((ZPD_UPPER - @competence) * 0.5)).clamp(COMPETENCE_FLOOR, COMPETENCE_CEILING)
          end

          def fade_support!
            idx = SUPPORT_LEVELS.index(@support_level) || 0
            return if idx >= SUPPORT_LEVELS.size - 1

            @support_level = SUPPORT_LEVELS[idx + 1]
          end

          def increase_support!
            idx = SUPPORT_LEVELS.index(@support_level) || (SUPPORT_LEVELS.size - 1)
            return if idx <= 0

            @support_level = SUPPORT_LEVELS[idx - 1]
          end

          def mastered?
            @competence >= MASTERY_THRESHOLD
          end

          def in_zpd?
            @competence >= ZPD_LOWER && @competence < ZPD_UPPER
          end

          def to_h
            {
              id:                @id,
              skill_name:        @skill_name,
              domain:            @domain,
              competence:        @competence.round(4),
              support_level:     @support_level,
              current_zone:      current_zone,
              practice_count:    @practice_count,
              mastered:          mastered?,
              in_zpd:            in_zpd?,
              created_at:        @created_at,
              last_practiced_at: @last_practiced_at,
              task_history_size: @task_history.size
            }
          end

          private

          def compute_delta(difficulty:, success:)
            if success
              in_active_zpd = difficulty >= ZPD_LOWER && difficulty < ZPD_UPPER
              in_active_zpd ? LEARNING_GAIN : LEARNING_GAIN / 2.0
            else
              -FAILURE_SETBACK
            end
          end

          def adjust_support(success)
            if success
              fade_support!
            else
              increase_support!
            end
          end

          def initial_support_level
            if @competence >= ZPD_UPPER
              :independent
            elsif @competence >= ZPD_LOWER
              :prompted
            else
              :full
            end
          end

          def record_task(difficulty:, success:)
            @task_history << {
              task_id:    SecureRandom.uuid,
              difficulty: difficulty,
              success:    success,
              support:    @support_level,
              at:         Time.now.utc
            }
            @task_history.shift while @task_history.size > MAX_HISTORY
          end
        end
      end
    end
  end
end
