module Bubbles
  class RestEnvironment
    attr_accessor :scheme, :host, :port, :api_key, :api_key_name

    ##
    # Construct a new instance of +RestEnvironment+.
    #
    # @param [String] scheme The scheme to use for communicating with the host. Currently, http and https are supported.
    # @param [String] host The host to communicate with.
    # @param [Integer] port The port on which the communication channel should operate.
    # @param [String] api_key (Optional) The API key to use to identify your client with the API. Defaults to +nil+.
    # @param [String] api_key_name (Optional) The name of the header that will specify the API key. Defaults to +"X-API-Key"+.
    #
    def initialize(scheme='https', host='api.foamfactory.com', port=443, api_key=nil, api_key_name='X-API-Key')
      @scheme = scheme
      @port = port

      if @scheme == 'http' && @port == 443
        @port = 80
      end

      @host = host
      @api_key = api_key
      @api_key_name = api_key_name
    end

    def api_key_name
      unless @api_key_name
        @api_key_name = 'X-API-Key'
      end

      @api_key_name
    end
  end
end