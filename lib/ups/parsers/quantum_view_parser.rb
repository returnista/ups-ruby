require 'base64'
require 'tempfile'
require 'ox'

module UPS
  module Parsers
    class QuantumViewParser < BaseParser
      def quantum_view_events
        root_response[:QuantumViewEvents]
      end

      private

      def root_response
        parsed_response[:QuantumViewResponse]
      end
    end
  end
end
