require 'bubbles/config'
require 'bubbles/rest_environment'

module Bubbles
  class RestClientResources
    def local_environment
      Bubbles.configuration.local_environment
    end

    def staging_environment
      Bubbles.configuration.staging_environment
    end

    def production_environment
      Bubbles.configuration.production_environment
    end

    ##
    # Create a new instance of +RestClientResources+.
    #
    # @param env The +RestEnvironment+ that should be used for this set of resources.
    # @param api_key The API key to use to send to the host for unauthenticated requests.
    #
    def initialize(env, api_key)
      unless env
        env = :local
      end

      unless api_key
        api_key = ''
      end

      @environment = get_environment env
      @api_key = api_key
      @auth_token = nil
    end

    ##
    # Execute a GET request without authentication.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the GET call.
    #
    def self.execute_get_unauthenticated(env, endpoint)
      url = endpoint.get_expanded_url env

      begin
        if env.scheme == 'https'
          response = RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .get({
                   :content_type => :json,
                   :accept => :json
                 })
        else
          response = RestClient.get(url.to_s,
                                    {
                                      :content_type => :json
                                    })
        end
      rescue Errno::ECONNREFUSED
        return {:error => 'Unable to connect to host ' + env.host.to_s + ':' + env.port.to_s}.to_json
      end

      unless endpoint.expect_json
        return response
      end

      return JSON.parse(response, object_class: OpenStruct)
    end

    ##
    # Execute a GET request with authentication.
    #
    # Currently, only Authorization: Bearer is supported.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token to use for authentication.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the GET call.
    #
    def self.execute_get_authenticated(env, endpoint, auth_token)
      url = endpoint.get_expanded_url env

      begin
        if env.scheme == 'https'
          response = RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .get({
                   :authorization => 'Bearer ' + auth_token,
                   :content_type => :json,
                   :accept => :json
                 })
        else
          response = RestClient.get(url.to_s,
                                    {
                                      :authorization => 'Bearer ' + auth_token,
                                      :content_type => :json
                                    })
        end
      rescue Errno::ECONNREFUSED
        response = {:error => 'Unable to connect to host ' + env.host.to_s + ':' + env.port.to_s}.to_json
      end

      unless endpoint.expect_json
        return response
      end

      return JSON.parse(response, object_class: OpenStruct)
    end

    ##
    # Execute a POST request without authentication, but requiring an API key.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] api_key The API key to use to process the request. Will be placed in an 'X-API-KEY' header.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] headers (Optional) A +Hash+ of key-value pairs that will be sent as HTTP headers as part of the
    #        request. Defaults to +nil+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the POST call.
    #
    def self.execute_post_unauthenticated_with_api_key(env, endpoint, api_key, data, headers=nil)
      additional_headers = {
        'X-Api-Key' => api_key
      }

      url = endpoint.get_expanded_url env

      if endpoint.expect_json
        additional_headers[:accept] = 'application/json'
      end

      unless headers.nil?
        headers.each { |nextHeader|
          additional_headers[nextHeader[0]] = nextHeader[1]
        }
      end

      begin
        if env.scheme == 'https'
          response = RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .post(data.to_json, additional_headers)
        else
          response = RestClient.post url.to_s, data.to_json, additional_headers
        end
      rescue Errno::ECONNREFUSED
        response = { :error => 'Unable to connect to host ' + env.host.to_s + ":" + env.port.to_s }.to_json
      end

      unless endpoint.expect_json
        return response
      end

      JSON.parse(response, object_class: OpenStruct)
    end

    ##
    # Execute a POST request with authentication in the form of an authorization token.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token retrieved during some former authentication call. Will be
    #        placed into a Authorization header.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the POST call.
    #
    def self.execute_post_authenticated(env, endpoint, auth_token, data)
      if auth_token.nil?
        raise 'Cannot execute an authenticated POST request with no auth_token'
      end

      if data.nil?
        raise 'Cannot execute POST command with an empty data set'
      end

      url = endpoint.get_expanded_url env

      begin
        headers = {
          :content_type => :json,
          :authorization => 'Bearer ' + auth_token
        }

        if endpoint.expect_json
          headers[:accept] = :json
        end

        if env.scheme == 'https'
          response = RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .post(data.to_json, headers)

        else
          response = RestClient.post(url.to_s, data.to_json, headers)
        end
      rescue Errno::ECONNREFUSED
        response = { :error => 'Unable to connect to host ' + env.host.to_s + ':' + env.port.to_s }.to_json
      end

      unless endpoint.expect_json
        return response
      end

      JSON.parse(response, object_class: OpenStruct)
    end

    ##
    # Retrieve the {RestEnvironment} to utilize from a {Symbol} describing it.
    #
    # @param [Symbol] environment A {Symbol} describing the environment to use. Must be one of:
    #        [:production, :staging, :local, nil]. If +nil+, note that +:production+ will be used.
    #
    # @return [RestEnvironment] The {RestEnvironment} corresponding to the given {Symbol}.
    #
    def get_environment(environment)
      if !environment || environment == :production
        return self.production_environment
      elsif environment == :staging
        return self.staging_environment
      end


      self.local_environment
    end
  end
end