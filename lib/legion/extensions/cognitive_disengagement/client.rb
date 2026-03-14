# frozen_string_literal: true

require 'legion/extensions/cognitive_disengagement/helpers/constants'
require 'legion/extensions/cognitive_disengagement/helpers/goal'
require 'legion/extensions/cognitive_disengagement/helpers/disengagement_engine'
require 'legion/extensions/cognitive_disengagement/runners/cognitive_disengagement'

module Legion
  module Extensions
    module CognitiveDisengagement
      class Client
        include Runners::CognitiveDisengagement

        def initialize(**)
          @engine = Helpers::DisengagementEngine.new
        end
      end
    end
  end
end
