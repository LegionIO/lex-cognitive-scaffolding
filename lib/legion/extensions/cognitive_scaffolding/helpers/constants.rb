# frozen_string_literal: true

module Legion
  module Extensions
    module CognitiveScaffolding
      module Helpers
        module Constants
          MAX_SCAFFOLDS      = 100
          MAX_TASKS          = 500
          MAX_HISTORY        = 300

          DEFAULT_COMPETENCE = 0.3
          COMPETENCE_FLOOR   = 0.0
          COMPETENCE_CEILING = 1.0

          ZPD_LOWER = 0.3
          ZPD_UPPER = 0.8

          SUPPORT_LEVELS = %i[full guided prompted independent].freeze

          FADING_RATE          = 0.1
          MASTERY_THRESHOLD    = 0.85
          FRUSTRATION_THRESHOLD = 0.15

          LEARNING_GAIN   = 0.08
          FAILURE_SETBACK = 0.03
          DECAY_RATE      = 0.01

          ZONE_LABELS = {
            (0.85..)     => :mastered,
            (0.3...0.85) => :zpd,
            (..0.3)      => :beyond_reach
          }.freeze
        end
      end
    end
  end
end
