# frozen_string_literal: true

require 'legion/extensions/cognitive_scaffolding/helpers/constants'
require 'legion/extensions/cognitive_scaffolding/helpers/scaffold'
require 'legion/extensions/cognitive_scaffolding/helpers/scaffolding_engine'
require 'legion/extensions/cognitive_scaffolding/runners/cognitive_scaffolding'

module Legion
  module Extensions
    module CognitiveScaffolding
      class Client
        include Runners::CognitiveScaffolding

        attr_reader :engine

        def initialize(engine: nil, **)
          @engine = engine || Helpers::ScaffoldingEngine.new
        end
      end
    end
  end
end
