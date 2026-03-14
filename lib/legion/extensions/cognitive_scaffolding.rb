# frozen_string_literal: true

require 'legion/extensions/cognitive_scaffolding/version'
require 'legion/extensions/cognitive_scaffolding/helpers/constants'
require 'legion/extensions/cognitive_scaffolding/helpers/scaffold'
require 'legion/extensions/cognitive_scaffolding/helpers/scaffolding_engine'
require 'legion/extensions/cognitive_scaffolding/runners/cognitive_scaffolding'

module Legion
  module Extensions
    module CognitiveScaffolding
      extend Legion::Extensions::Core if Legion::Extensions.const_defined? :Core
    end
  end
end
