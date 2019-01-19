require 'addressable/template'

module Bubbles
  ##
  # Representation of a single API endpoint within the Bubbles infrastructure.
  #
  # In order to access an API Endpoint, an {RestEnvironment} must also be provided. This class is an abstract
  # representation of an +Endpoint+, without any information provided as part of the Environment. In other words, an
  # Endpoint can be used with any +RestEnvironment+.
  #
  class Endpoint
    ## Controls the method used to access the endpoint. Must be one of {Endpoint::Methods}.
    # @return [Symbol] the method used to access the endpoint. Will always be one of the symbols defined in {Endpoint::METHODS}.
    attr_accessor :method

    ## Controls the location, relative to the web root of the host, used to access the endpoint.
    # @return [String] the location relative to the web root of the host used to access the endpoint
    attr_accessor :location

    ## Controls whether authentication is required to access this endpoint. Defaults to false.
    # @return [Boolean] true, if authentication is required to access this endpoint; false, otherwise.
    attr_accessor :authentication_required

    ## Controls whether an API key is required to access this endpoint. Defaults to false.
    # @return [Boolean] true, if an API key is required to access this endpoint; false, otherwise.
    attr_accessor :api_key_required

    ## A template for specifying the complete URL for endpoints.
    API_URL = ::Addressable::Template.new("{scheme}://{host}/{endpoint}")

    ## A template for specifying the complete URL for endpoints, with a port attached to the host.
    API_URL_WITH_PORT = ::Addressable::Template.new("{scheme}://{host}:{port}/{endpoint}")


    ## The HTTP methods supported by a rest client utilizing Bubbles.
    METHODS = %w[get].freeze

    ##
    # Construct a new instance of an Endpoint.
    #
    # @param [Symbol] method The type of the new Endpoint to create. Must be one of the methods in {Endpoint::METHODS}.
    # @param [String] location The location, relative to the root of the host, at which the endpoint resides.
    # @param [Boolean] auth_required If true, then authorization/authentication is required to access this endpoint.
    #        Defaults to +false+.
    # @param [Boolean] api_key_required If true, then an API key is required to access this endpoint. Defaults to
    #        +false+.
    #
    def initialize(method, location, auth_required = false, api_key_required = false)
      @method = method
      @location = location
      @auth_required = auth_required
      @api_key_required = api_key_required

      # Strip the leading slash from the endpoint location, if it's there
      if @location.to_s[0] == '/'
        @location = @location.to_s.slice(1, @location.to_s.length)
      end
    end

    ##
    # Retrieve a +String+ that will identify this +Endpoint+ uniquely within a hash table.
    #
    # @return [String] A unique identifier for this Endpoint, including its method (get/post/put/etc..), location, whether or not it is authenticated, and whether it needs an API key to successfully execute.
    #
    def get_key_string
      auth_string = '-unauthenticated'
      if @auth_required
        auth_string = '-authenticated'
      end

      api_key_string = ''
      if @api_key_required
        api_key_string = '-with-api-key'
      end

      method.to_s + "-" + @location.to_s + auth_string + api_key_string
    end

    ##
    # Retrieve the base URL template for this +Endpoint+, given a +RestEnvironment+.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to access this endpoint.
    #
    # @return [Addressable::Template] A +Template+ containing the URL to use to access this +Endpoint+.
    #
    def get_base_url(env)
      unless env.port == 80 || env.port == 443
        return API_URL_WITH_PORT
      end

      API_URL
    end

    ##
    # Retrieve the URL to access this +Endpoint+, as a +String+ with all parameters expanded.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to access this +Endpoint+.
    #
    # @return [String] A +String+ containing the full URL to access this +Endpoint+ on the given {RestEnvironment}.
    #
    def get_expanded_url(env)
      url = get_base_url env

      if is_complex?
        special_url_string = '{scheme}://{environment_host}/'
        unless @port == 80 || @port == 443
          special_url_string = '{scheme}://{environment_host}:{port}/'
        end

        special_url_string = special_url_string + @location
        url = ::Addressable::Template.new(special_url_string)

        return url.expand(scheme: env.scheme, host: env.host, port: env.port)
      end

      url.expand(scheme: env.scheme, host: env.host, port: env.port, endpoint: @location)
    end

    ##
    # Determine if the location for this Endpoint is complex.
    #
    # @return [Boolean] true, if the location for this Endpoint is complex (contains a '/'); false, otherwise.
    def is_complex?
      @location.include? '/'
    end

    ##
    # Retrieve a String representing the location of this Endpoint.
    #
    # Complex Endpoints will have instances of '/' replaced with '_'.
    #
    # @return [String] The string representation of the location of this endpoint.
    def get_location_string
      unless is_complex?
        return @location
      end

      @location.to_s.gsub('/', '_')
    end

    ##
    # Determine if this +Endpoint+ requires authentication/authorization to utilize
    #
    # @return [Boolean] true, if this +Endpoint+ requires authentication/authorization to use; false, otherwise.
    def authenticated?
      @auth_required
    end
  end
end