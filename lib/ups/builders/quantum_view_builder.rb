require 'ox'

module UPS
  module Builders
    # The {QuantumViewBuilder} class builds UPS XML QuantumView Objects.
    #
    # @author Paul Trippett
    # @since 0.1.0
    # @attr [String] name The Containing XML Element Name
    # @attr [Hash] opts The Organization and Address Parts
    class QuantumViewBuilder < BuilderBase
      include Ox

      # Initializes a new {QuantumViewBuilder} object
      def initialize
        super 'QuantumViewRequest'

        add_request 'QVEvents'
      end

      # Adds a Request section to the XML document being built
      #
      # @param [String] action The UPS API Action requested
      # @return [void]
      def add_request(action)
        root << Element.new('Request').tap do |request|
          request << element_with_value('RequestAction', action)
        end
      end
    end
  end
end
