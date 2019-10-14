require "bubbles/version"
require 'bubbles/config'
require 'base64'
require 'bubbles/rest_client_resources'
require 'bubbles/rest_environment'
require 'bubbles/version'
# require 'exceptions'
require 'rest-client'
require 'json'

module Bubbles
  class Resources < RestClientResources
    def initialize(api_key='')
      super

      @packageName = Bubbles::VersionInformation.package_name
      @versionName = Bubbles::VersionInformation.version_name
      @versionCode = Bubbles::VersionInformation.version_code
    end

    def get_version_info
      {
        :name => @packageName,
        :versionName => @versionName,
        :versionCode => @versionCode
      }
    end
  end
end
