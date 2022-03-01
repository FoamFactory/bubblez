require 'spec_helper'
require 'bubblez/endpoint'
require 'bubblez/rest_environment'

describe Bubblez::Endpoint do
  describe '#initialize' do
    context 'when the method is GET' do
      context 'when no authentication is required' do
        it 'should create an endpoint for /version' do
          ep = Bubblez::Endpoint.new(:get, 'version')

          expect(ep.get_key_string).to eq('get-version-unauthenticated')
        end
      end

      context 'when authentication is required' do
        it 'should create a simple endpoint for /versions' do
          ep = Bubblez::Endpoint.new(:get, 'versions', true)

          expect(ep.get_key_string).to eq('get-versions-authenticated')
        end

        context 'when the endpoint contains a URI parameter' do
          it 'should show the URI parameter in the expanded url' do
            ep = Bubblez::Endpoint.new(:get, 'student/{id}', true)

            expect(ep.uri_params).to contain_exactly(:id)
          end
        end
      end
    end

    context 'when the method is POST' do
      context 'when no authentication is required' do
        context 'when an API key is required' do
          it 'should create an endpoint for /login' do
            ep = Bubblez::Endpoint.new(:post, 'login', false, true)

            expect(ep.get_key_string).to eq('post-login-unauthenticated-with-api-key')
          end
        end
      end
    end
  end

  describe '#name' do
    it 'should set the name of the method to "hello"' do
      @endpoint = Bubblez::Endpoint.new(:post, 'do_something', false, false)
      @endpoint.name = 'hello'

      expect(@endpoint.name).to eq('hello')
      expect(@endpoint.name?).to be_truthy
    end
  end

  describe '#get_base_url' do
    context 'when the port is not a standard port' do
      before do
        @endpoint = Bubblez::Endpoint.new(:post, 'do_something', false, false)
        @environment = Bubblez::RestEnvironment.new('http', 'somewhere.something.com', 9216)
      end

      it 'should show the base url with the port included' do
        expect(@endpoint.get_expanded_url(@environment).to_s).to eq('http://somewhere.something.com:9216/do_something')
      end
    end

    context 'when the port is a standard port' do
      before do
        @endpoint = Bubblez::Endpoint.new(:post, 'do_something', false, false)
        @environment = Bubblez::RestEnvironment.new('http', 'somewhere.something.com', 80)
      end

      it 'should show the base url with the port not included' do
        expect(@endpoint.get_expanded_url(@environment).to_s).to eq('http://somewhere.something.com/do_something')
      end
    end
  end

  describe '#is_complex' do
    context 'after having created an endpoint at /versions/new' do
      it 'should show that the endpoint is complex' do
        ep = Bubblez::Endpoint.new(:get, '/versions/new')

        expect(ep.location).to eq('versions/new')
        expect(ep.is_complex?).to eq(true)
      end
    end
  end

  describe '#get_location' do
    context 'with an endpoint that is complex' do
      it 'should replace all instances of / with _ in the location string' do
        ep = Bubblez::Endpoint.new :get, 'versions'

        expect(ep.get_location_string).to eq('versions')

        ep = Bubblez::Endpoint.new :get, '/management/clients/new'

        expect(ep.get_location_string).to eq('management_clients_new')
      end
    end
  end

  describe '#has_additional_headers' do
    context 'with an endpoint that has additional headers' do
      before do
        @endpoint = Bubblez::Endpoint.new :get, 'versions', false, false, nil, :body_as_string, {}, {
            :'MyHeader' => "Value"
        }
      end

      it 'should show that additional headers are included in the endpoint' do
        expect(@endpoint.has_additional_headers?).to be_truthy
      end
    end
  end
end
