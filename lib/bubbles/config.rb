require 'bubbles/rest_environment'
require 'bubbles/endpoint'
require 'base64'

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
      @environment_scheme = 'http'
      @environment_host = '127.0.0.1'
      @environment_port = '1234'
      @environment_api_key = nil

      @endpoints = Hash.new
    end

    ##
    # Retrieve the {RestEnvironment} object defined as part of this Configuration.
    #
    # Note that this constructs a new +RestEnvironment+ and returns it, rather than returning an existing object.
    #
    def environment
      RestEnvironment.new(@environment_scheme, @environment_host, @environment_port, @environment_api_key)
    end

    ##
    # Set the current environment.
    #
    # @param [Object] env The environment, as a generic Ruby Object.
    #
    # @example In app/config/environments/staging.rb:
    #    Bubbles.configure do |config|
    #      config.environment = {
    #         :scheme => 'https',
    #         :host => 'stage.api.somehost.com',
    #         :port => '443'
    #      }
    #    end
    #
    def environment=(env)
      @environment_scheme = env[:scheme]
      @environment_host = env[:host]
      @environment_port = env[:port]
      @environment_api_key = env[:api_key]
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
        endpoint_object = Endpoint.new ep[:method], ep[:location].to_s, ep[:authenticated], ep[:api_key_required], ep[:name], ep[:return_type], ep[:encode_authorization]

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

        if Bubbles::RestEnvironment.instance_methods(false).include?(endpoint_name_as_sym)
          Bubbles::RestEnvironment.class_exec do
            remove_method endpoint_name_as_sym
          end
        end

        if endpoint.method == :get
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params|
                  RestClientResources.execute_get_authenticated self, endpoint, auth_token, uri_params
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token|
                  RestClientResources.execute_get_authenticated self, endpoint, auth_token, {}
                end
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do
                RestClientResources.execute_get_unauthenticated self, endpoint
              end
            end
          end
        elsif endpoint.method == :post
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do |auth_token, data|
                RestClientResources.execute_post_authenticated self, endpoint, auth_token, data
              end
            end
          else
            if endpoint.api_key_required?
              Bubbles::RestEnvironment.class_exec do
                define_method(endpoint_name_as_sym) do |data|
                  additional_headers = {}
                  if endpoint.encode_authorization_header?
                    count = 0
                    auth_value = ''
                    endpoint.encode_authorization.each { |auth_key|
                      if data[auth_key]
                        if count > 0
                          auth_value = auth_value + ':' + data[auth_key]
                        else
                          auth_value = data[auth_key]
                        end

                        count = count + 1

                        data.delete(auth_key)
                      end
                    }

                    additional_headers[:Authorization] = 'Basic ' + Base64.strict_encode64(auth_value)
                  end

                  RestClientResources.execute_post_with_api_key self, endpoint, self.api_key, data, additional_headers
                end
              end
            else
              raise 'Unauthenticated POST requests without an API key are not allowed'
            end
          end
        elsif endpoint.method == :delete
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params|
                  RestClientResources.execute_delete_authenticated self, endpoint, auth_token, uri_params
                end
              else
                # NOTE: While MDN states that DELETE requests with a body are allowed, it seems that a number of
                # documentation sites discourage its use. Thus, it's possible that, depending on the server API
                # framework, the DELETE request could be rejected. As such, we're disallowing it here, BUT if we
                # get feedback from users that it should be supported, we can add support for it.
                raise 'DELETE requests without URI parameters are not allowed'
              #   define_method(endpoint_name_as_sym) do |auth_token|
              #     RestClientResources.execute_delete_authenticated self, endpoint, auth_token, {}
              #   end
              end
            end
          else
            raise 'Unauthenticated DELETE requests are not allowed'
            # Bubbles::RestEnvironment.class_exec do
              # define_method(endpoint_name_as_sym) do
              #   RestClientResources.execute_delete_unauthenticated self, endpoint
              # end
            # end
          end
        elsif endpoint.method == :patch
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params, data|
                  RestClientResources.execute_patch_authenticated self, endpoint, auth_token, uri_params, data
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token, data|
                  RestClientResources.execute_patch_authenticated self, endpoint, auth_token, nil, data
                end
              end
            end
          else
            raise 'Unauthenticated PATCH requests are not implemented'
            # Bubbles::RestEnvironment.class_exec do
            # define_method(endpoint_name_as_sym) do
            #   RestClientResources.execute_delete_unauthenticated self, endpoint
            # end
            # end
          end
        elsif endpoint.method == :put
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params, data|
                  RestClientResources.execute_put_authenticated self, endpoint, auth_token, uri_params, data
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token, data|
                  RestClientResources.execute_put_authenticated self, endpoint, auth_token, nil, data
                end
              end
            end
          else
            raise 'Unauthenticated PUT requests are not implemented'
            # Bubbles::RestEnvironment.class_exec do
            # define_method(endpoint_name_as_sym) do
            #   RestClientResources.execute_delete_unauthenticated self, endpoint
            # end
            # end
          end
        elsif endpoint.method == :head
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params|
                  RestClientResources.execute_head_authenticated self, endpoint, auth_token, uri_params
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token|
                  RestClientResources.execute_head_authenticated self, endpoint, auth_token, {}
                end
              end
            end
          elsif endpoint.api_key_required?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |api_key, uri_params|
                  additional_headers = {}
                  additional_headers['X-Api-Key'] = api_key
                  RestClientResources.execute_head_unauthenticated self, endpoint, uri_params, additional_headers
                end
              else
                define_method(endpoint_name_as_sym) do |api_key|
                  additional_headers = {}
                  additional_headers['X-Api-Key'] = api_key
                  RestClientResources.execute_head_unauthenticated self, endpoint, {}, additional_headers
                end
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |uri_params|
                  RestClientResources.execute_head_unauthenticated self, endpoint, uri_params, {}
                end
              else
                define_method(endpoint_name_as_sym) do
                  RestClientResources.execute_head_unauthenticated self, endpoint, {}, {}
                end
              end
            end
          end
        end
      end
    end
  end
end
