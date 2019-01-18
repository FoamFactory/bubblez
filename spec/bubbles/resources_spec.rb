require 'bubbles'
require 'spec_helper'

describe Bubbles::Resources do
  describe 'Endpoints' do
    before do
      Bubbles.configure do |config|
        config.endpoints = [
          {
            :type => :get,
            :location => :version,
            :authenticated => false,
            :api_key_required => false
          }
        ]
      end
    end

    it 'should create a method "version" on each RestEnvironment' do
      resources = Bubbles::Resources.new
      methods = Bubbles::RestEnvironment.instance_methods(false)
      expect(Bubbles::RestEnvironment.instance_methods(false).include?(:version)).to eq(true)
    end
  end
  describe '#production_environment' do
    before do
      Bubbles.configure do |config|
        config.production_environment = {
          :scheme => 'https',
          :host => 'www.foamfactorybrewing.com',
          :port => '443'
        }
      end
    end

    it 'returns an address of https://www.foamfactorybrewing.com:443 for production environment' do
      resources = Bubbles::Resources.new
      production_env = resources.production_environment

      expect(production_env).to_not be_nil
      expect(production_env.scheme).to eq('https')
      expect(production_env.host).to eq('www.foamfactorybrewing.com')
      expect(production_env.port).to eq('443')
    end
  end

  describe '#staging_environment' do
    before do
      Bubbles.configure do |config|
        config.staging_environment = {
          :scheme => 'https',
          :host => 'stage.foamfactorybrewing.com',
          :port => '443'
        }
      end
    end

    it 'returns an address of https://stage.foamfactorybrewing.com:443 for staging environment' do
        resources = Bubbles::Resources.new
        staging_env = resources.staging_environment

        expect(staging_env).to_not be_nil
        expect(staging_env.scheme).to eq('https')
        expect(staging_env.host).to eq('stage.foamfactorybrewing.com')
        expect(staging_env.port).to eq('443')
    end
  end

  describe '#local_environment' do
    before do
      Bubbles.configure do |config|
        config.local_environment = {
          :scheme => 'https',
          :host => '127.0.1.1',
          :port => '2222'
        }
      end
    end

    it 'returns an address of https://127.0.1.1:2222 for local environment' do
      resources = Bubbles::Resources.new
      local_env = resources.local_environment

      expect(local_env).to_not be_nil
      expect(local_env.scheme).to eq('https')
      expect(local_env.host).to eq('127.0.1.1')
      expect(local_env.port).to eq('2222')
    end
  end

  describe '#get_environment' do
    before do
      Bubbles.configure do |config|
        config.local_environment = {
          :scheme => 'https',
          :host => '127.0.1.1',
          :port => '2222'
        }

        config.staging_environment = {
          :scheme => 'https',
          :host => 'stage.foamfactorybrewing.com',
          :port => '443'
        }

        config.production_environment = {
          :scheme => 'https',
          :host => 'www.foamfactorybrewing.com',
          :port => '443'
        }
      end
    end

    it 'should retrieve the correct environment when calling #get_environment' do
      resources = Bubbles::Resources.new
      local_env = resources.get_environment :local
      staging_env = resources.get_environment :staging
      production_env = resources.get_environment :production

      expect(local_env).to_not be_nil
      expect(local_env.scheme).to eq('https')
      expect(local_env.host).to eq('127.0.1.1')
      expect(local_env.port).to eq('2222')

      expect(staging_env).to_not be_nil
      expect(staging_env.scheme).to eq('https')
      expect(staging_env.host).to eq('stage.foamfactorybrewing.com')
      expect(staging_env.port).to eq('443')

      expect(production_env).to_not be_nil
      expect(production_env.scheme).to eq('https')
      expect(production_env.host).to eq('www.foamfactorybrewing.com')
      expect(production_env.port).to eq('443')
    end
  end
end