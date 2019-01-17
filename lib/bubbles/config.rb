require 'bubbles/RestEnvironment'

module Bubbles
  class << self
    attr_writer :configuration
  end

  def self.configure
    yield(configuration)
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

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
    end

    def local_environment
      RestEnvironment.new(@local_environment_scheme, @local_environment_host, @local_environment_port)
    end

    def local_environment=(env)
      @local_environment_scheme = env[:scheme]
      @local_environment_host = env[:host]
      @local_environment_port = env[:port]
    end

    def staging_environment
      RestEnvironment.new(@staging_environment_scheme, @staging_environment_host, @staging_environment_port)
    end

    def staging_environment=(env)
      @staging_environment_scheme = env[:scheme]
      @staging_environment_host = env[:host]
      @staging_environment_port = env[:port]
    end

    def production_environment
      RestEnvironment.new(@production_environment_scheme, @production_environment_host, @production_environment_port)
    end

    def production_environment=(env)
      @production_environment_scheme = env[:scheme]
      @production_environment_host = env[:host]
      @production_environment_port = env[:port]
    end
  end
end
