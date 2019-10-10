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

      if @scheme == 'http' && @port == nil
        @port = 80
      elsif @scheme == 'https' && @port == nil
        @port = 443
      end

      @host = host
      @api_key = api_key
      @api_key_name = api_key_name
    end

    ##
    # Retrieve the name of the API key to be used.
    #
    # This will be the "key" portion of the key-value of the API key header.
    #
    # @return [String] The API key name, if set; "X-API-Key", otherwise.
    #
    def api_key_name
      @api_key_name
    end

    ##
    # Retrieve an API key from this +RestEnvironment+, but only if a specific +Endpoint+ requires it.
    #
    # If an +Endpoint+ has +api_key_required+ set to +true+, this method will return the API for the current
    # +RestEnvironment+. If not, then it will return +nil+, rather than just blindly returning the API key for every
    # possible retrieval, even if the +Endpoint+ doesn't require it.
    #
    # @return [String] The API key for this +RestEnvironment+, if the specified +Endpoint+ requires it; +nil+,
    #         otherwise.
    #
    def get_api_key_if_needed(endpoint)
      if endpoint.api_key_required?
        @api_key
      else
        nil
      end
    end
  end
end