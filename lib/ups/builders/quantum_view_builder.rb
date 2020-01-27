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

      attr_accessor :access_doc, :main_doc

      # Initializes a new {QuantumViewBuilder} object
      def initialize
        instruct = Instruct.new(:xml)
        instruct[:version] = '1.0'

        self.access_doc = Document.new
        access_doc << instruct
        self.access_request = Element.new('AccessRequest')

        self.main_doc = Document.new
        main_doc << instruct
        self.main_root = Element.new('QuantumViewRequest')

        yield self if block_given?

        add_request('QVEvents')
      end

      def to_xml
        [access_doc.to_xml, main_doc.to_xml].join
      end

      private

      # Adds a Request section to the XML document being built
      #
      # @param [String] action The UPS API Action requested
      # @return [void]
      def add_request(action)
        main_root << Element.new('Request').tap do |request|
          request << element_with_value('RequestAction', action)
        end
      end

    end
  end
end
