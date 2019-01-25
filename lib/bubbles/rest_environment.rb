require 'addressable/template'

module Bubbles
  class RestEnvironment
    attr_accessor :scheme, :host, :port, :api_key

    ##
    # Construct a new instance of +RestEnvironment+.
    #
    # @param [String] scheme The scheme to use for communicating with the host. Currently, http and https are supported.
    # @param [String] host The host to communicate with.
    # @param [Integer] port The port on which the communication channel should operate.
    # @param [String] api_key (Optional) The API key to use to identify your client with the API. Defaults to +nil+.
    #
    def initialize(scheme='https', host='api.foamfactory.com', port=443, api_key=nil)
      @scheme = scheme
      @port = port

      if @scheme == 'http' && @port == 443
        @port = 80
      end

      @host = host
      @api_key = api_key
    end
  end
end