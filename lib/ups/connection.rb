require 'uri'
require 'excon'
require 'digest/md5'
require 'ox'

module UPS
  # The {Connection} class acts as the main entry point to performing rate and
  # ship operations against the UPS API.
  #
  # @author Paul Trippett
  # @abstract
  # @since 0.1.0
  # @attr [String] url The base url to use either TEST_URL or LIVE_URL
  class Connection
    attr_accessor :url

    TEST_URL = 'https://wwwcie.ups.com'
    LIVE_URL = 'https://onlinetools.ups.com'

    RATE_PATH = '/ups.app/xml/Rate'
    SHIP_CONFIRM_PATH = '/ups.app/xml/ShipConfirm'
    SHIP_ACCEPT_PATH = '/ups.app/xml/ShipAccept'
    ADDRESS_PATH = '/ups.app/xml/XAV'
    QUANTUM_VIEW_PATH = '/ups.app/xml/QVEvents'

    DEFAULT_PARAMS = {
      test_mode: false
    }

    # Initializes a new {Connection} object
    #
    # @param [Hash] params The initialization options
    # @option params [Boolean] :test_mode If TEST_URL should be used for
    #   requests to the UPS URL
    def initialize(params = {})
      params = DEFAULT_PARAMS.merge(params)
      self.url = (params[:test_mode]) ? TEST_URL : LIVE_URL
    end

    # Makes a request to fetch Rates for a shipment.
    #
    # A pre-configured {Builders::RateBuilder} object can be passed as the first
    # option or a block yielded to configure a new {Builders::RateBuilder}
    # object.
    #
    # @param [Builders::RateBuilder] rate_builder A pre-configured
    #   {Builders::RateBuilder} object to use
    # @yield [rate_builder] A RateBuilder object for configuring
    #   the shipment information sent
    def rates(rate_builder = nil)
      if rate_builder.nil? && block_given?
        rate_builder = UPS::Builders::RateBuilder.new
        yield rate_builder
      end

      response = get_response(RATE_PATH, rate_builder.to_xml)
      UPS::Parsers::RatesParser.new(response.body)
    end

    # Makes a request to ship a package
    #
    # A pre-configured {Builders::ShipConfirmBuilder} object can be passed as
    # the first option or a block yielded to configure a new
    # {Builders::ShipConfirmBuilder} object.
    #
    # @param [Builders::ShipConfirmBuilder] confirm_builder A pre-configured
    #   {Builders::ShipConfirmBuilder} object to use
    # @yield [ship_confirm_builder] A ShipConfirmBuilder object for configuring
    #   the shipment information sent
    def ship(confirm_builder = nil)
      if confirm_builder.nil? && block_given?
        confirm_builder = Builders::ShipConfirmBuilder.new
        yield confirm_builder
      end

      File.open('ship.xml', 'w') { |file| file.write(confirm_builder.to_xml) }

      confirm_response = make_confirm_request(confirm_builder)
      return confirm_response unless confirm_response.success?

      accept_builder = build_accept_request_from_confirm(confirm_builder, confirm_response)
      make_accept_request(accept_builder)
    end

    # Makes a request to get quantum view
    #
    # A pre-configured {Builders::QuantumViewBuilder} object can be passed as
    # the first option or a block yielded to configure a new
    # {Builders::QuantumViewBuilder} object.
    #
    # @param [Builders::QuantumViewBuilder] confirm_builder A pre-configured
    #   {Builders::QuantumViewBuilder} object to use
    # @yield [quantum_view_builder] A QuantumViewBuilder object for configuring
    #   the shipment information sent
    def track(tracking_builder = nil)
      if tracking_builder.nil? && block_given?
        tracking_builder = Builders::QuantumViewBuilder.new
        yield tracking_builder
      end

      ap tracking_builder.to_xml
      
      File.open('track.xml', 'w') { |file| file.write(tracking_builder.to_xml) }

      make_tracking_request(tracking_builder)
    end

    private

    def build_url(path)
      "#{url}#{path}"
    end

    def get_response(path, body)
      Excon.post(build_url(path), body: body)
    end

    def make_confirm_request(confirm_builder)
      make_ship_request(confirm_builder, SHIP_CONFIRM_PATH, Parsers::ShipConfirmParser)
    end

    def make_accept_request(accept_builder)
      make_ship_request(accept_builder, SHIP_ACCEPT_PATH, Parsers::ShipAcceptParser)
    end

    def make_tracking_request(tracking_builder)
      make_ship_request(tracking_builder, QUANTUM_VIEW_PATH, Parsers::QuantumViewParser)
    end

    def make_ship_request(builder, path, ship_parser)
      response = get_response(path, builder.to_xml)
      ship_parser.new(response.body)
    end

    def build_accept_request_from_confirm(confirm_builder, confirm_response)
      UPS::Builders::ShipAcceptBuilder.new.tap do |builder|
        builder.add_access_request confirm_builder.license_number,
                                   confirm_builder.user_id,
                                   confirm_builder.password
        builder.add_shipment_digest confirm_response.shipment_digest
      end
    end
  end
end
