require "bubblez/version"
require 'bubblez/config'
require 'base64'
require 'bubblez/rest_client_resources'
require 'bubblez/rest_environment'
require 'bubblez/version'
require 'rest-client'
require 'json'

module Bubblez
  class Resources < RestClientResources
    def initialize(name, api_key='')
      super

      @config = Bubblez.configuration[name]
      @package_name = Bubblez::VersionInformation.package_name
      @version_name = Bubblez::VersionInformation.version_name
      @version_code = Bubblez::VersionInformation.version_code
    end

    def config
      @config
    end

    def get_version_info
      {
        :name => @package_name,
        :version_name => @version_name,
        :version_code => @version_code
      }
    end
  end
end
