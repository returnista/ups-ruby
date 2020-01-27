require 'base64'
require 'tempfile'
require 'ox'

module UPS
  module Parsers
    class QuantumViewParser < BaseParser
      def quantum_view_events
        root_response[:QuantumViewEvents]
      end

      def record_to_file
        File.open('quantum_view.json', 'wb') { |file| file.write(Ox.load(response, mode: :object))}
      end

      private

      def root_response
        parsed_response[:QuantumViewResponse]
      end
    end
  end
end
