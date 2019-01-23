require 'bubbles/rest_environment'
require 'bubbles/endpoint'

module Bubbles
  class << self
    attr_writer :configuration
  end

  ##
  # Configure the Bubbles instance.
  #
  # Use this method if you want to configure the Bubbles instance, typically during intialization of your Gem or
  # application.
  #
  # @example In app/config/initializers/bubbles.rb
  #    Bubbles.configure do |config|
  #      config.endpoints = [
  #        {
  #          :type => :get,
  #          :location => :version,
  #          :authenticated => false,
  #          :api_key_required => false
  #        }
  #      ]
  #    end
  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  ##
  # The configuration of the Bubbles rest client.
  #
  # Use this class if you want to retrieve configuration values set during initialization.
  #
  class Configuration
    def initialize
      @local_environment_scheme = 'http'
      @local_environment_host = '127.0.0.1'
      @local_environment_port = '1234'

      @staging_environment_scheme = 'http'
      @staging_environment_host = '127.0.0.1'
      @staging_environment_port = '1234'

      @production_environment_scheme = 'http'
      @production_environment_host = '127.0.0.1'
      @production_environment_port = '1234'

      @endpoints = Hash.new
    end

    ##
    # Retrieve the local {RestEnvironment} object defined as part of this Configuration.
    #
    def local_environment
      RestEnvironment.new(@local_environment_scheme, @local_environment_host, @local_environment_port)
    end

    ##
    # Set the local environment.
    #
    # @param [Object] env The environment, as a generic Ruby Object.
    #
    # @example In app/config/initializers/bubbles.rb
    #    Bubbles.configure do |config|
    #      config.local_environment = {
    #         :scheme => 'https',
    #         :host => 'api.somehost.com',
    #         :port => '443'
    #      }
    #    end
    #
    def local_environment=(env)
      @local_environment_scheme = env[:scheme]
      @local_environment_host = env[:host]
      @local_environment_port = env[:port]
    end

    ##
    # Retrieve the staging {RestEnvironment} object defined as part of this Configuration.
    #
    def staging_environment
      RestEnvironment.new(@staging_environment_scheme, @staging_environment_host, @staging_environment_port)
    end

    ##
    # Set the staging environment.
    #
    # @param [Object] env The environment, as a generic Ruby Object.
    #
    # @example In app/config/initializers/bubbles.rb
    #    Bubbles.configure do |config|
    #      config.staging_environment = {
    #         :scheme => 'https',
    #         :host => 'api.somehost.com',
    #         :port => '443'
    #      }
    #    end
    #
    def staging_environment=(env)
      @staging_environment_scheme = env[:scheme]
      @staging_environment_host = env[:host]
      @staging_environment_port = env[:port]
    end

    ##
    # Retrieve the production {RestEnvironment} object defined as part of this Configuration.
    #
    def production_environment
      RestEnvironment.new(@production_environment_scheme, @production_environment_host, @production_environment_port)
    end

    ##
    # Set the production environment.
    #
    # @param [Object] env The environment, as a generic Ruby Object.
    #
    # @example In app/config/initializers/bubbles.rb
    #    Bubbles.configure do |config|
    #      config.production_environment = {
    #         :scheme => 'https',
    #         :host => 'api.somehost.com',
    #         :port => '443'
    #      }
    #    end
    #
    def production_environment=(env)
      @production_environment_scheme = env[:scheme]
      @production_environment_host = env[:host]
      @production_environment_port = env[:port]
    end

    ##
    # Retrieve the list of +Endpoint+s configured in this +Configuration+ object.
    #
    # @return {Array} An Array of {Endpoint}s.
    #
    def endpoints
      @endpoints
    end

    ##
    # Add all {Endpoint} objects within this {Configuration} instance.
    #
    # {Endpoint} objects are defined using two required parameters: type and location, and three optional parameters:
    # authenticated, api_key_required and name.
    #   - method: Indicates the HTTP method used to access the endpoint. Must be one of {Endpoint::METHODS}.
    #   - location: Indicates the path at which the {Endpoint} can be accessed on the host environment.
    #   - authenticated: (Optional) A true or false value indicating whether the {Endpoint} requires an authorization
    #                    token to access it. Defaults to false.
    #   - api_key_required: (Optional) A true or false value indicating whether the {Endpoint} requires a API key to
    #                       access it. Defaults to false.
    #   - name: (Optional): A +String+ indicating the name of the method to add. If not provided, the method name will
    #           be the same as the +location+.
    #
    def endpoints=(endpoints)
      new_endpoints = Hash.new
      endpoints.each do |ep|
        endpoint_object = Endpoint.new ep[:method], ep[:location].to_s, ep[:authenticated], ep[:api_key_required], ep[:name], ep[:expect_json]

        new_endpoints[endpoint_object.get_key_string] = endpoint_object
      end

      @endpoints = new_endpoints

      # Define all of the endpoints as methods on RestEnvironment
      @endpoints.values.each do |endpoint|
        if endpoint.name != nil
          endpoint_name_as_sym = endpoint.name.to_sym
        else
          endpoint_name_as_sym = endpoint.get_location_string.to_sym
        end

        if Bubbles::RestEnvironment.instance_methods(false).include? (endpoint_name_as_sym)
          Bubbles::RestEnvironment.class_exec do
            remove_method endpoint_name_as_sym
          end
        end

        if endpoint.method == :get
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do |auth_token|
                RestClientResources.execute_get_authenticated self, endpoint, auth_token
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do
                RestClientResources.execute_get_unauthenticated self, endpoint
              end
            end
          end
        end
      end
    end
  end
end
