require 'date'

module Bubblez
  class VersionInformation
    def self.package_name
      return 'bubblez'
    end

    def self.version_name
      '1.0.1'
    end

    def self.version_code
      get_code_from_version_name version_name
    end

    def self.get_code_from_version_name(name)
      # The version code should be the patch version * 1 + the minor version * 2 + the major version * 4
      splitVersion = name.split('.')

      4 * splitVersion[0].to_i + 2 * splitVersion[1].to_i + splitVersion[2].to_i
    end
  end
end
