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

      response
    end

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