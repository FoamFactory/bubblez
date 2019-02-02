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
    ##
    # Controls the method used to access the endpoint. Must be one of {Endpoint::Methods}.
    # @return [Symbol] the method used to access the endpoint. Will always be one of the symbols defined in {Endpoint::METHODS}.
    attr_accessor :method

    ##
    # Controls the location, relative to the web root of the host, used to access the endpoint.
    # @return [String] the location relative to the web root of the host used to access the endpoint
    attr_accessor :location

    ##
    # Controls whether authentication is required to access this endpoint. Defaults to false.
    # @return [Boolean] true, if authentication is required to access this endpoint; false, otherwise.
    attr_accessor :authentication_required

    ##
    # Controls whether an API key is required to access this endpoint. Defaults to false.
    # @return [Boolean] true, if an API key is required to access this endpoint; false, otherwise.
    attr_accessor :api_key_required

    ##
    # Controls whether JSON is the expected form of output from this +Endpoint+.
    # @return [Boolean] true, if JSON is the expected form of output from this +Endpoint+; false, otherwise.
    attr_accessor :expect_json

    ##
    # Controls which data values should be encoded as part of an Authorization header. They will be separated with a
    # colon in the order they are received and Base64-encoded.
    # @return [Array] An array of +Symbol+s specifying which of the data attributes should be Base64-encoded as part of
    #         an Authorization header. The values will be encoded in the order they are received.
    attr_accessor :encode_authorization

    ##
    # An array of parameters that are specified on the URI of this endpoint for each call.
    attr_accessor :uri_params

    ## A template for specifying the complete URL for endpoints.
    API_URL = ::Addressable::Template.new("{scheme}://{host}/{endpoint}")

    ## A template for specifying the complete URL for endpoints, with a port attached to the host.
    API_URL_WITH_PORT = ::Addressable::Template.new("{scheme}://{host}:{port}/{endpoint}")


    ## The HTTP methods supported by a rest client utilizing Bubbles.
    METHODS = %w[get post].freeze

    ##
    # Construct a new instance of an Endpoint.
    #
    # @param [Symbol] method The type of the new Endpoint to create. Must be one of the methods in {Endpoint::METHODS}.
    # @param [String] location The location, relative to the root of the host, at which the endpoint resides.
    # @param [Boolean] auth_required If true, then authorization/authentication is required to access this endpoint.
    #        Defaults to +false+.
    # @param [Boolean] api_key_required If true, then an API key is required to access this endpoint. Defaults to
    #        +false+.
    # @param [String] name An optional name which will be given to the method that will execute this {Endpoint} within
    #        the context of a {RestClientResources} object.
    # @param [Boolean] expect_json Whether or not to expect a JSON response from this +Endpoint+. Defaults to +false+.
    #
    def initialize(method, location, auth_required = false, api_key_required = false, name = nil, expect_json = false, encode_authorization = {})
      @method = method
      @location = location
      @auth_required = auth_required
      @api_key_required = api_key_required
      @name = name
      @expect_json = expect_json
      @encode_authorization = encode_authorization
      @uri_params = []

      # Strip the leading slash from the endpoint location, if it's there
      if @location.to_s[0] == '/'
        @location = @location.to_s.slice(1, @location.to_s.length)
      end

      # Extract URI parameters and create symbols for them
      # URI parameters are enclosed by curly braces '{' and '}'
      @location.to_s.split('/').each do |uri_segment|

        match_data = /\{(.*)\}/.match(uri_segment)
        unless match_data == nil
          @uri_params.push(match_data[1].to_sym)
        end
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
    def get_expanded_url(env, uri_params = {})
      url = get_base_url env

      if is_complex?
        special_url_string = '{scheme}://{host}/'
        unless @port == 80 || @port == 443
          special_url_string = '{scheme}://{host}:{port}/'
        end

        special_url_string = special_url_string + @location

        uri_params.each do |param, value|
          needle = "{#{param.to_s}}"
          special_url_string = special_url_string.sub(needle, value.to_s)
        end

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

    ##
    # Determine if an API key is required
    #
    # @return [Boolean] true, if an API key is required to make the request; false, otherwise.
    def api_key_required?
      api_key_required
    end

    ##
    # Set the name of the method on {RestClientResources} used to access this {Endpoint}.
    #
    # @param [String] name The name of the method used to access this {Endpoint}.
    #
    def name=(name)
      @name = name
    end

    ##
    # Retrieve the name of the method on {RestClientResources} used to access this {Endpoint}.
    #
    # @return [String] A String containing the name of the method on {RestClientResources} used to access this
    #         {Endpoint}, or +nil+ if one wasn't provided.
    #
    def name
      @name
    end

    ##
    # Determine if this {Endpoint} has a method name, different from the +location+ name, specified for it.
    #
    # @return [Boolean] true, if this {Endpoint} has a method name that is different than the +location+ name specified
    #         for the +Endpoint+, to be defined on {RestClientResources}; false, otherwise.
    #
    def name?
      @name == nil
    end

    ##
    # Whether or not an Authorization header should be Base64-encoded.
    #
    # @return [Boolean] true, if attributes from the data array have been specified to be Base64-encoded as part of an
    #         Authorization header; false, otherwise.
    #
    def encode_authorization_header?
      @encode_authorization.length > 0
    end

    def has_uri_params?
      !@uri_params.empty?
    end
  end
end