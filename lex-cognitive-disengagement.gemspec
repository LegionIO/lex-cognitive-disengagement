# frozen_string_literal: true

require_relative 'lib/legion/extensions/cognitive_disengagement/version'

Gem::Specification.new do |spec|
  spec.name          = 'lex-cognitive-disengagement'
  spec.version       = Legion::Extensions::CognitiveDisengagement::VERSION
  spec.authors       = ['Esity']
  spec.email         = ['matthewdiverson@gmail.com']

  spec.summary       = 'Goal disengagement and sunk cost detection for LegionIO cognitive agents'
  spec.description   = 'Strategic withdrawal engine based on Wrosch et al. goal disengagement theory — ' \
                       'detects sunk cost bias, assesses opportunity cost, and recommends disengagement ' \
                       'from low-progress goals'
  spec.homepage      = 'https://github.com/LegionIO/lex-cognitive-disengagement'
  spec.license       = 'MIT'
  spec.required_ruby_version = '>= 3.4'

  spec.metadata['homepage_uri']          = spec.homepage
  spec.metadata['source_code_uri']       = 'https://github.com/LegionIO/lex-cognitive-disengagement'
  spec.metadata['documentation_uri']     = 'https://github.com/LegionIO/lex-cognitive-disengagement'
  spec.metadata['changelog_uri']         = 'https://github.com/LegionIO/lex-cognitive-disengagement'
  spec.metadata['bug_tracker_uri']       = 'https://github.com/LegionIO/lex-cognitive-disengagement/issues'
  spec.metadata['rubygems_mfa_required'] = 'true'

  spec.files         = Dir['lib/**/*']
  spec.require_paths = ['lib']
  spec.add_development_dependency 'legion-gaia'
end
