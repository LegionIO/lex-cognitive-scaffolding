# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_scaffolding/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-scaffolding'
  spec.version       = Legion::Extensions::CognitiveScaffolding::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'LEX Cognitive Scaffolding'
  spec.description   = "Vygotsky's Zone of Proximal Development modeled for brain-based agentic AI: " \
                       'graduated support scaffolding with automatic fading as competence grows'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-scaffolding'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-cognitive-scaffolding'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-cognitive-scaffolding'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-cognitive-scaffolding'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-cognitive-scaffolding/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir.glob('{lib,spec}/**/*') + %w[lex-cognitive-scaffolding.gemspec Gemfile LICENSE README.md]
  end
  spec.require_paths = ['lib']
end
