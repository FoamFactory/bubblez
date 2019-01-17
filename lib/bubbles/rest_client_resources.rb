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

    def execute_get_unauthenticated(endpoint)
      begin
        if @environment.scheme == 'https'
          response = RestClient::Resource.new(endpoint, :verify_ssl => OpenSSL::SSL::VERIFY_NONE)
            .get({
                   :content_type => :json,
                   :accept => :json
                 })
        else
          response = RestClient.get(endpoint,
                                    {
                                      :content_type => :json
                                    })
        end
      rescue Errno::ECONNREFUSED
        return {:error => 'Unable to connect to host ' + @environment.host.to_s + ':' + @environment.port.to_s}.to_json
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