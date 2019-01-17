require 'addressable/template'

module Bubbles
  class RestEnvironment
    API_URL = ::Addressable::Template.new("{scheme}://{environment_host}/{endpoint}")
    API_URL_WITH_ROOT = ::Addressable::Template.new("{scheme}://{environment_host}:{port}/{endpoint}")

    attr_accessor :scheme, :host, :endpoint, :port

    ##
    # Construct a new instance of +RestEnvironment+.
    #
    # @param scheme The scheme to use for communicating with the host. Currently, http and https are supported.
    # @param host The host to communicate with.
    # @param port The port on which the communication channel should operate.
    #
    def initialize(scheme='https', host='api.foamfactory.com', port=443)
      @scheme = scheme
      @port = port

      if @scheme == 'http' && @port == 443
        @port = 80
      end

      @host = host

      @endpoints = Hash.new
    end

    ##
    # Add an unauthenticated endpoint to this +RestEnvironment+.
    #
    # @param type The type of the endpoint. Must be one of [:get].
    # @param endpoint The path to the endpoint, without the leading slash.
    #
    def add_unauthenticated_endpoint(type, endpoint)
      if type == :get
        unless endpoint.include? "/"
          @endpoints[endpoint] = get_url.expand(scheme: @scheme, environment_host: @host, port: @port, endpoint: endpoint).to_s
          return
        end

        @endpoints[endpoint] = get_url_with_special_endpoint.expand(scheme: @scheme, environment_host: @host, port: @port, endpoint: endpoint).to_s
      end
    end

    def get_endpoint_string(endpoint)
      @endpoints[endpoint]
    end

    private

    ##
    # Get an addressable template for a 'special' endpoint (one containing '/' characters)
    #
    # @param endpoint The endpoint to get an addressable URL to.
    #
    # @returns The ::Addressable::Template without the endpoint parameter encoded in the URI.
    #
    def get_url_with_special_endpoint(endpoint)
      special_url_string = '{scheme}://{environment_host}/'
      unless @port == 80 || @port == 443
        special_url_string = '{scheme}://{environment_host}:{port}/'
      end

      special_url_string = special_url_string + endpoint
      ::Addressable::Template.new(special_url_string)
    end

    def get_url
      unless @port == 80 || @port == 443
        return API_URL_WITH_ROOT
      end

      API_URL
    end
  end
end