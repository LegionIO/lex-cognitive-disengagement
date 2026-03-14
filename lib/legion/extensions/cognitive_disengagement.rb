# frozen_string_literal: true

require 'legion/extensions/cognitive_disengagement/version'
require 'legion/extensions/cognitive_disengagement/helpers/constants'
require 'legion/extensions/cognitive_disengagement/helpers/goal'
require 'legion/extensions/cognitive_disengagement/helpers/disengagement_engine'
require 'legion/extensions/cognitive_disengagement/runners/cognitive_disengagement'
require 'legion/extensions/cognitive_disengagement/client'

module Legion
  module Extensions
    module CognitiveDisengagement
      extend Legion::Extensions::Core if Legion::Extensions.const_defined?(:Core)
    end
  end
end
