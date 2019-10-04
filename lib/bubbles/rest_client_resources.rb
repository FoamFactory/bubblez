require 'bubbles/config'
require 'bubbles/rest_environment'

module Bubbles
  class RestClientResources
    def environment
      Bubbles.configuration.environment
    end

    ##
    # Create a new instance of +RestClientResources+.
    #
    # @param env The +RestEnvironment+ that should be used for this set of resources.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    def initialize(env, api_key = nil, api_key_name='X-API-Key')
      unless env
        env = :local
      end

      unless api_key
        api_key = ''
      end

      @api_key = api_key
      @auth_token = nil
      @api_key_name = api_key_name
    end

    ##
    # Execute a GET request without authentication.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the GET call.
    #
    def self.execute_get_unauthenticated(env, endpoint, uri_params, additional_headers = {}, api_key = nil, api_key_name='X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, nil, nil, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .get(headers)
        else
          next RestClient.get(url.to_s, headers)
        end
      end
    end

    ##
    # Execute a GET request with authentication.
    #
    # Currently, only Authorization: Bearer is supported.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token to use for authentication.
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the GET call.
    #
    def self.execute_get_authenticated(env, endpoint, auth_token, uri_params, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, nil, auth_token, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .get(headers)
        else
          next RestClient.get(url.to_s, headers)
        end
      end
    end

    ##
    # Execute a HEAD request without authentication.
    #
    # This is the same as a GET request, but will only return headers and not the response body.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the GET call.
    #
    def self.execute_head_unauthenticated(env, endpoint, uri_params, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, nil, nil, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .head(headers)
        else
          next RestClient.head(url.to_s, headers)
        end
      end
    end

    ##
    # Execute a HEAD request with authentication.
    #
    # Currently, only Authorization: Bearer is supported. This is the same as a GET request, but will only return
    # headers and not the response body.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token to use for authentication.
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the HEAD call.
    #
    def self.execute_head_authenticated(env, endpoint, auth_token, uri_params, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, nil, auth_token, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .head(headers)
        else
          next RestClient.head(url.to_s, headers)
        end
      end
    end

    ##
    # Execute a HEAD request without authentication but with some parameters encoded in the URI string.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the HEAD call.
    #
    def self.execute_head_unauthenticated_with_uri_params(env, endpoint, uri_params, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, nil, nil, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .head(headers)
        else
          next RestClient.head(url.to_s, headers)
        end
      end
    end

    ##
    # Execute a POST request without authentication, but requiring an API key.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] api_key The API key to use to process the request. Will be placed in an 'X-API-KEY' header.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the POST call.
    #
    def self.execute_post_unauthenticated(env, endpoint, data, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, data, nil, composite_headers) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .post(data.to_json, headers)
        else
          next RestClient.post url.to_s, data.to_json, headers
        end
      end
    end

    ##
    # Execute a POST request with authentication in the form of an authorization token.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token retrieved during some former authentication call. Will be
    #        placed into a Authorization header.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the POST call.
    #
    def self.execute_post_authenticated(env, endpoint, auth_token, data, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      return execute_rest_call(env, endpoint, data, auth_token, composite_headers) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .post(data.to_json, headers)

        else
          next RestClient.post(url.to_s, data.to_json, headers)
        end
      end
    end

    ##
    # Execute a PATCH request with authentication in the form of an authorization token.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token retrieved during some former authentication call. Will be
    #        placed into a Authorization header.
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the PATCH call.
    #
    def self.execute_patch_authenticated(env, endpoint, auth_token, uri_params, data, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      return execute_rest_call(env, endpoint, data, auth_token, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .patch(data.to_json, headers)

        else
          next RestClient.patch(url.to_s, data.to_json, headers)
        end
      end
    end

    ##
    # Execute a PATCH request without authentication.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the PATCH call.
    #
    def self.execute_patch_unauthenticated(env, endpoint, uri_params, data, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      return execute_rest_call(env, endpoint, data, nil, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .patch(data.to_json, headers)
        else
          next RestClient.patch(url.to_s, data.to_json, headers)
        end
      end
    end

    ##
    # Execute a PUT request with authentication in the form of an authorization token.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token retrieved during some former authentication call. Will be
    #        placed into a Authorization header.
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the PUT call.
    #
    def self.execute_put_authenticated(env, endpoint, auth_token, uri_params, data, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      return execute_rest_call(env, endpoint, data, auth_token, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .put(data.to_json, headers)

        else
          next RestClient.put(url.to_s, data.to_json, headers)
        end
      end
    end

    ##
    # Execute a PUT request without authentication.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] data A +Hash+ of key-value pairs that will be sent in the body of the http request.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the PUT call.
    #
    def self.execute_put_unauthenticated(env, endpoint, uri_params, data, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      return execute_rest_call(env, endpoint, data, nil, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .put(data.to_json, headers)
        else
          next RestClient.put(url.to_s, data.to_json, headers)
        end
      end
    end

    ##
    # Execute a DELETE request with authentication in the form of an authorization token.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to execute the request
    # @param [Endpoint] endpoint The +Endpoint+ which should be requested
    # @param [String] auth_token The authorization token retrieved during some former authentication call. Will be
    #        placed into a Authorization header.
    # @param [Hash] uri_params A +Hash+ of identifiers to values to replace in the URI string.
    # @param [Hash] additional_headers A +Hash+ of key-value pairs that will be sent as additional headers in the API
    #        call. Defaults to an empty +Hash+.
    # @param [String] api_key (Optional) The API key to use to send to the host for unauthenticated requests. Defaults
    #        to +nil+.
    # @param [String] api_key_name (Optional) The name of the header in which to send the API key. Defaults to
    #        +"X-API-Key"+.
    #
    # @return [RestClient::Response] The +Response+ resulting from the execution of the DELETE call.
    #
    def self.execute_delete_authenticated(env, endpoint, auth_token, uri_params, additional_headers = {}, api_key = nil, api_key_name = 'X-API-Key')
      if api_key and endpoint.api_key_required?
        composite_headers = RestClientResources.build_composite_headers(additional_headers, {
            api_key_name.to_s => api_key
        })
      else
        composite_headers = additional_headers
      end

      execute_rest_call(env, endpoint, nil, auth_token, composite_headers, uri_params) do |env, url, data, headers|
        if env.scheme == 'https'
          next RestClient::Resource.new(url.to_s, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .delete(headers)
        else
          next RestClient.delete(url.to_s, headers)
        end
      end
    end

    ##
    # Retrieve the {RestEnvironment} to utilize from a {Symbol} describing it.
    #
    # @param [Symbol] environment A {Symbol} describing the environment to use. Must be one of:
    #        [:production, :staging, :local, nil]. If +nil+, note that +:production+ will be used.
    #
    # @return [RestEnvironment] The {RestEnvironment} corresponding to the given {Symbol}.
    #
    # def get_environment(environment)
    #   if !environment || environment == :production
    #     return self.production_environment
    #   elsif environment == :staging
    #     return self.staging_environment
    #   end
    #
    #
    #   self.local_environment
    # end

    ##
    # Build a set of headers from two existing sets.
    #
    # This takes two sets of headers, as +Hash+es and merges them to create a single +Hash+ with all of the members of
    # the previous two.
    #
    # @param [Hash] headers A set of existing headers.
    # @param [Hash] additional_headers Another set of headers
    #
    # @return A +Hash+ containing all of the members of the input parameters. Key conflicts will be resolved to the
    #         benefit of +additional_headers+, meaning that whatever is in the value of the key within the
    #         +additional_headers+ +Hash+ will be used.
    #
    def self.build_composite_headers(headers, additional_headers)
      composite_headers = headers

      unless additional_headers.empty?
        additional_headers.each { |nextHeader|
          composite_headers[nextHeader[0]] = nextHeader[1]
        }
      end

      composite_headers
    end

    ##
    # Retrieve an encoded authorization (username and password) for a given
    # +Endpoint+ and data set.
    #
    # @param endpoint The +Endpoint+ that this authorization will be used for.
    # @param data A set of elements (typically username and password) that
    #        should be encoded.
    #
    # @return A +String+ containing an encoding of the values passed in as
    #         +data+, concatenated with a colon.
    #
    def self.get_encoded_authorization(endpoint, data)
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

      auth_value
    end

    private

    ##
    # Execute a REST call to the API.
    #
    # This is the workhorse of the +RestClientResources+ class. It performs the necessary setup of headers and the HTTP
    # request, and then executes the remote API call.
    #
    # @param [RestEnvironment] env The +RestEnvironment+ to use to make this API call. Must not be +nil+.
    # @param [Endpoint] The +Endpoint+ to call. Must not be +nil+.
    # @param [Hash] The body of the request. May be +nil+ or empty for requests not requiring a body.
    # @param [String] auth_token The authorization token used to authenticate to the API. May be +nil+ for requests that
    #        don't require authentication.
    # @param [Hash] headers A +Hash+ of key-value pairs to add to the HTTP request as headers. May be +nil+ if none are
    #        required.
    # @param [Block] block The block to execute that actually performs the HTTP request.
    #
    # @return [RestClient::Response|OpenStruct] If "expect_json" is enabled for the +Endpoint+ being executed, then this
    #         will return an +OpenStruct+; otherwise, the +Response+ will be returned.
    #
    def self.execute_rest_call(env, endpoint, data, auth_token, headers, uri_params = {}, &block)
      unless block
        raise ArgumentError('This method requires that a block is given.')
      end

      url = endpoint.get_expanded_url env, uri_params

      begin
        if data == nil
          data = {}
        end

        if headers == nil
          headers = {
            :content_type => :json
          }
        else
          headers[:content_type] = :json
        end

        unless auth_token == nil
          headers[:authorization] = 'Bearer ' + auth_token
        end

        headers[:accept] = :json

        response = block.call(env, url, data, headers)
      rescue Errno::ECONNREFUSED
        response = { :error => 'Unable to connect to host ' + env.host.to_s + ':' + env.port.to_s }.to_json
      end

      if endpoint.return_type == :body_as_object and endpoint.method != :head
          return JSON.parse(response, object_class: OpenStruct)
      elsif endpoint.return_type == :body_as_string and endpoint.method != :head
        return response.body
      end

      response
    end
  end
end
