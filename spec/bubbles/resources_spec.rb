require 'bubbles'
require 'spec_helper'

describe Bubbles::Resources do
  describe 'Endpoints' do
    before do
      Bubbles.configure do |config|
        config.endpoints = [
          {
            :method => :get,
            :location => :version,
            :authenticated => false,
            :api_key_required => false
          },
          {
            :method => :get,
            :location => :students,
            :authenticated => true,
            :api_key_required => false,
            :name => :list_students
          }
        ]

        config.local_environment = {
          :scheme => 'http',
          :host => '127.0.0.1',
          :port => '1234'
        }

        config.staging_environment = {
          :scheme => 'http',
          :host => '127.0.0.1',
          :port => '1234'
        }
      end
    end

    it 'should create a method "version" on each RestEnvironment' do
      expect(Bubbles::RestEnvironment.instance_methods(false).include?(:version)).to eq(true)
    end

    it 'should create a method "list_students" on each RestEnvironment' do
      expect(Bubbles::RestEnvironment.instance_methods(false).include?(:list_students)).to eq(true)
    end

    describe 'GET requests' do
      describe 'unauthenticated' do
        it 'should be able to retrieve a version from localhost' do
          VCR.use_cassette('get_version_unauthenticated') do
            resources = Bubbles::Resources.new
            local_env = resources.local_environment

            response = JSON.parse(local_env.version, object_class: OpenStruct)
            expect(response).to_not be_nil
            expect(response.name).to eq('Sinking Moon API')
            expect(response.versionName).to eq('2.0.0')

            deploy_date = Date.parse(response.deployDate)
            expect(deploy_date.year).to eq(2018)
            expect(deploy_date.month).to eq(1)
            expect(deploy_date.day).to eq(2)
          end
        end
      end

      describe 'authenticated' do
        it 'should be able to list students from the staging environment' do
          VCR.use_cassette('get_students_authenticated') do
            auth_token = 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJjcmVhdGlvbl9kYXRlIjoiMjAxNy0xMC0xNVQxMToyNjozMS0wNTowMCIsImV4cGlyYXRpb25fZGF0ZSI6IjIwMTctMTEtMTRUMTE6MjY6MzEtMDU6MDAiLCJ1c2VyX2lkIjoxfQ.dyCWwE4wk7aTfjnGncsqp_jq5QyICKYQPkBh5nLQwFU'
            resources = Bubbles::Resources.new
            local_env = resources.local_environment

            response = JSON.parse(local_env.list_students(auth_token), object_class: OpenStruct)
            expect(response).to_not be_nil

            students = response.students
            expect(students.length).to eq(1)
            expect(students[0].name).to eq('Joe Blow')
            expect(students[0].zip).to eq('90263')
          end
        end
      end
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