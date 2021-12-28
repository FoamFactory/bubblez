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
  # Use this method if you want to configure the Bubbles instance, typically during initialization of your Gem or
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
      @environments = Hash.new
      @endpoints = Hash.new
    end

    ##
    # Retrieve the {RestEnvironment} object defined as part of this Configuration having a specified name.
    #
    # @param [String] environment_name The name of the {RestEnvironment} to retrieve.
    #
    # The +environment_name+ is +nil+ by default, which will return the default configuration, if only one exists.
    #
    # @return [RestEnvironment] A new +RestEnvironment+ having the configuration that was created with key
    #         +environment_name+. Note that +RestEnvironment+s are essentially immutable once they are created, so
    #         an existing object will _never_ be returned.
    #
    def environment(environment_name = nil)
      if environment_name.nil?
        if @environments.length > 1
          raise 'You must specify an environment_name parameter because more than one environment is defined'
        end

        env_hash = @environments[nil]
      else
        env_hash = @environments[environment_name]
      end

      if env_hash.nil?
        if environment_name.nil?
          raise 'No default environment specified'
        end

        raise 'No environment specified having name {}', environment_name
      end

      RestEnvironment.new(env_hash[:scheme], env_hash[:host], env_hash[:port], env_hash[:api_key],
                          env_hash[:api_key_name])
    end

    ##
    # Set the environments that can be used.
    #
    # @param [Array] environments The environments, as an array with each entry a +Hash+.
    #
    # One or more environments may be specified, but if more than one environment is specified, it is required that each
    # environment have a +:environment_name:+ parameter to differentiate it from other environments.
    #
    # @example In app/config/environments/staging.rb:
    #    Bubbles.configure do |config|
    #      config.environments = [{
    #         :scheme => 'https',
    #         :host => 'stage.api.somehost.com',
    #         :port => '443',
    #         :api_key => 'something',
    #         :api_key_name => 'X-API-Key' # Optional
    #      }]
    #    end
    #
    def environments=(environments)
      default = nil
      environments.each do |environment|
        if environments.length > 1 && environment[:environment_name].nil?
          message = 'More than one environment was specified and at least one of the environments does not have an ' \
                    ':environment_name field. Verify all environments have an :environment_name.'

          raise message
        end

        @environments = {}
        env_api_key = 'X-API-Key'
        env_api_key = environment[:api_key_name] if environment.key? :api_key_name

        @environments[environment[:environment_name]] = {
          scheme: environment[:scheme],
          host: environment[:host],
          port: environment[:port],
          api_key: environment[:api_key],
          api_key_name: env_api_key
        }
      end
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
        endpoint_object = Endpoint.new ep[:method], ep[:location].to_s, ep[:authenticated], ep[:api_key_required], ep[:name], ep[:return_type], ep[:encode_authorization], ep[:headers]

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
                if endpoint.encode_authorization_header?
                  define_method(endpoint_name_as_sym) do |username, password, uri_params|
                    login_data = {
                      :login => username,
                      :password => password
                    }
                    auth_value = RestClientResources.get_encoded_authorization(endpoint, login_data)
                    RestClientResources.execute_get_authenticated self, endpoint, :basic, auth_value, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                  end
                else
                  define_method(endpoint_name_as_sym) do |auth_token, uri_params|
                    RestClientResources.execute_get_authenticated self, endpoint, :bearer, auth_token, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                  end
                end
              else
                if endpoint.encode_authorization_header?
                  define_method(endpoint_name_as_sym) do |username, password|
                    login_data = {
                      :username => username,
                      :password => password
                    }
                    auth_value = RestClientResources.get_encoded_authorization(endpoint, login_data)

                    RestClientResources.execute_get_authenticated self, endpoint, :basic, auth_value, {}, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                  end
                else
                  define_method(endpoint_name_as_sym) do |auth_token|
                    RestClientResources.execute_get_authenticated self, endpoint, :bearer, auth_token, {}, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                  end
                end
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |uri_params|
                  RestClientResources.execute_get_unauthenticated self, endpoint, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do
                  RestClientResources.execute_get_unauthenticated self, endpoint, {}, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          end
        elsif endpoint.method == :post
          if endpoint.authenticated? and !endpoint.encode_authorization_header?
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do |auth_token, data|
                RestClientResources.execute_post_authenticated self, endpoint, :bearer, auth_token, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
              end
            end
          elsif endpoint.encode_authorization_header?
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do |username, password, data = {}|
                login_data = {
                  :username => username,
                  :password => password
                }

                auth_value = RestClientResources.get_encoded_authorization(endpoint, login_data)
                # composite_headers = RestClientResources.build_composite_headers(endpoint.additional_headers, {
                #                                                                   Authorization: 'Basic ' + Base64.strict_encode64(auth_value)
                #                                                                 })
                RestClientResources.execute_post_authenticated self, endpoint, :basic, auth_value, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              define_method(endpoint_name_as_sym) do |data|
                composite_headers = endpoint.additional_headers
                RestClientResources.execute_post_unauthenticated self, endpoint, data, composite_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
              end
            end
          end
        elsif endpoint.method == :delete
          if endpoint.has_uri_params?
            if endpoint.authenticated?
              Bubbles::RestEnvironment.class_exec do
                define_method(endpoint_name_as_sym) do |auth_token, uri_params|
                  RestClientResources.execute_delete_authenticated self, endpoint, auth_token, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            else
              Bubbles::RestEnvironment.class_exec do
                define_method(endpoint_name_as_sym) do |uri_params|
                  RestClientResources.execute_delete_unauthenticated self, endpoint, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          else
            # XXX_jwir3: While MDN states that DELETE requests with a body are allowed, it seems that a number of
            # documentation sites discourage its use. Thus, it's possible that, depending on the server API
            # framework, the DELETE request could be rejected. In addition, RestClient doesn't seem to support DELETE
            # requests with a body, so we're a bit stuck on this one, even if we wanted to support it.
            raise 'DELETE requests without URI parameters are not allowed'
          end
        elsif endpoint.method == :patch
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params, data|
                  RestClientResources.execute_patch_authenticated self, endpoint, auth_token, uri_params, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token, data|
                  RestClientResources.execute_patch_authenticated self, endpoint, auth_token, {}, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |uri_params, data|
                  RestClientResources.execute_patch_unauthenticated self, endpoint, uri_params, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do |data|
                  RestClientResources.execute_patch_unauthenticated self, endpoint, {}, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          end
        elsif endpoint.method == :put
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params, data|
                  RestClientResources.execute_put_authenticated self, endpoint, auth_token, uri_params, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token, data|
                  RestClientResources.execute_put_authenticated self, endpoint, auth_token, {}, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |uri_params, data|
                  RestClientResources.execute_put_unauthenticated self, endpoint, uri_params, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do |data|
                  RestClientResources.execute_put_unauthenticated self, endpoint, {}, data, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          end
        elsif endpoint.method == :head
          if endpoint.authenticated?
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |auth_token, uri_params|
                  RestClientResources.execute_head_authenticated self, endpoint, auth_token, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do |auth_token|
                  RestClientResources.execute_head_authenticated self, endpoint, auth_token, {}, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          else
            Bubbles::RestEnvironment.class_exec do
              if endpoint.has_uri_params?
                define_method(endpoint_name_as_sym) do |uri_params|
                  RestClientResources.execute_head_unauthenticated self, endpoint, uri_params, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              else
                define_method(endpoint_name_as_sym) do
                  RestClientResources.execute_head_unauthenticated self, endpoint, {}, endpoint.additional_headers, self.get_api_key_if_needed(endpoint), self.api_key_name
                end
              end
            end
          end
        end
      end
    end
  end
end
