require 'base64'
require 'tempfile'

module UPS
  module Parsers
    class QuantumViewParser < BaseParser
      def quantum_view_events
        xml =  root_response[:QuantumViewEvents]
        Ox.load(xml, mode: :hash)
      end

      private

      def root_response
        parsed_response[:QuantumViewResponse]
      end
    end
  end
end
