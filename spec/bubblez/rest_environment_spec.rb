require 'spec_helper'
require 'bubblez'

describe Bubblez::RestEnvironment do
  describe '#initialize' do
    context 'for an environment that specifies a scheme of http and a default port' do
      before do
        Bubblez.configure do |config|
          config['Default'].environments = [{
            scheme: 'http',
            host: 'somewhere.something.net',
          }]
        end
      end

      it 'should actually set the port to 80' do
        resources = Bubblez::Resources.new 'Default'
        env = resources.environment
        expect(env.port).to eq(80)
      end
    end

    context 'for an environment that specifies a scheme of https and a default port' do
      before do
        Bubblez.configure do |config|
          config['Default'].environments = [{
            scheme: 'https',
            host: 'somewhere.something.net',
          }]
        end
      end

      it 'should actually set the port to 443' do
        resources = Bubblez::Resources.new 'Default'
        env = resources.environment
        expect(env.port).to eq(443)
      end
    end
  end

  describe 'Bubblez::Configure' do
    before do
      Bubblez.configure do |config|
        config['Default'].endpoints = [
          {
            method: :get,
            location: :students,
            authenticated: true,
            api_key_required: false,
            name: :list_students
          },
          {
            method: :post,
            location: :login,
            authenticated: false,
            api_key_required: true
          },
          {
            method: :get,
            location: :version,
            authenticated: false,
            api_key_required: false
          }
        ]

        config['Default'].environments = [{
          scheme: 'http',
          host: '127.0.0.1',
          port: '1234',
          environment_name: 'local'
        }]
      end
    end

    it 'should create a method "version" on each RestEnvironment' do
      expect(Bubblez::RestEnvironment.instance_methods(false).include?(:version)).to eq(true)
    end

    it 'should create a method "list_students" on each RestEnvironment' do
      expect(Bubblez::RestEnvironment.instance_methods(false).include?(:list_students)).to eq(true)
    end

    it 'should create a method "login" on each RestEnvironment' do
      expect(Bubblez::RestEnvironment.instance_methods(false).include?(:login)).to eq(true)
    end
  end

  describe '#environments' do
    before do
      Bubblez.configure do |config|
        config['Default'].environments = [{
          scheme: 'https',
          host: '127.0.1.1',
          port: '2222',
          environment_name: 'local'
        }]
      end
    end

    describe 'with more than one environment specified where one or more do not have an environment name' do
      it 'should raise an exception' do
        expect {
          Bubblez.configure do |config|
            config['Default'].environments = [
              {
                scheme: 'https',
                host: '127.0.1.1',
                port: '2222',
                environment_name: 'local'
              },
              {
                scheme: 'https',
                host: '127.0.1.2',
                port: '2223',
              }]
          end
        }.to raise_error(RuntimeError, 'More than one environment was specified and at least one of the environments does not have an :environment_name field. Verify all environments have an :environment_name.')
      end
    end

    it 'returns an address of https://127.0.1.1:2222' do
      resources = Bubblez::Resources.new 'Default'
      environment = resources.environment 'local'

      expect(environment).to_not be_nil
      expect(environment.scheme).to eq('https')
      expect(environment.host).to eq('127.0.1.1')
      expect(environment.port).to eq('2222')
    end
  end

  describe '#api_key_name' do
    context 'for an environment that has an API key name specified' do
      before do
        Bubblez.configure do |config|
          config['Default'].environments = [{
            scheme: 'https',
            host: '127.0.1.1',
            port: '2222',
            api_key_name: 'X-Something-Key',
            api_key: 'blahblahblah'
          }]
        end
      end

      it 'should return the name of the API key' do
        resources = Bubblez::Resources.new 'Default'
        env = resources.environment
        expect(env.api_key_name).to eq('X-Something-Key')
      end
    end

    context 'for an environment that does not have an API key name specified' do
      before do
        Bubblez.configure do |config|
          config['Default'].environments = [{
            scheme: 'https',
            host: '127.0.1.1',
            port: '2222',
            api_key: 'blahblahblah'
          }]
        end
      end

      it 'should return "X-API-Key"' do
        resources = Bubblez::Resources.new 'Default'
        env = resources.environment
        expect(env.api_key_name).to eq('X-API-Key')
      end
    end
  end

  # describe '#get_environment' do
  #   before do
  #     Bubblez.configure do |config|
  #       config.environment = {
  #         :scheme => 'https',
  #         :host => '127.0.1.1',
  #         :port => '2222'
  #       }
  #
  #       config.staging_environment = {
  #         :scheme => 'https',
  #         :host => 'stage.foamfactorybrewing.com',
  #         :port => '443'
  #       }
  #
  #       config.production_environment = {
  #         :scheme => 'https',
  #         :host => 'www.foamfactorybrewing.com',
  #         :port => '443'
  #       }
  #     end
  #   end
  #
  #   it 'should retrieve the correct environment' do
  #     resources = Bubblez::Resources.new
  #     local_env = resources.get_environment :local
  #     staging_env = resources.get_environment :staging
  #     production_env = resources.get_environment :production
  #
  #     expect(local_env).to_not be_nil
  #     expect(local_env.scheme).to eq('https')
  #     expect(local_env.host).to eq('127.0.1.1')
  #     expect(local_env.port).to eq('2222')
  #
  #     expect(staging_env).to_not be_nil
  #     expect(staging_env.scheme).to eq('https')
  #     expect(staging_env.host).to eq('stage.foamfactorybrewing.com')
  #     expect(staging_env.port).to eq('443')
  #
  #     expect(production_env).to_not be_nil
  #     expect(production_env.scheme).to eq('https')
  #     expect(production_env.host).to eq('www.foamfactorybrewing.com')
  #     expect(production_env.port).to eq('443')
  #   end
  # end
end
