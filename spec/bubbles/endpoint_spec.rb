require 'spec_helper'
require 'bubbles/endpoint'

describe Bubbles::Endpoint do
  describe '#initialize' do
    context 'when the method is GET' do
      context 'when no authentication is required' do
        it 'should create an endpoint for /version' do
          ep = Bubbles::Endpoint.new(:get, 'version')

          expect(ep.get_key_string).to eq('get-version-unauthenticated')
        end
      end

      context 'when authentication is required' do
        it 'should create a simple endpoint for /versions' do
          ep = Bubbles::Endpoint.new(:get, 'versions', true)

          expect(ep.get_key_string).to eq('get-versions-authenticated')
        end

        context 'when the endpoint contains a URI parameter' do
          it 'should show the URI parameter in the expanded url' do
            ep = Bubbles::Endpoint.new(:get, 'student/{id}', true)

            expect(ep.uri_params).to contain_exactly(:id)
          end
        end
      end
    end

    context 'when the method is POST' do
      context 'when no authentication is required' do
        context 'when an API key is required' do
          it 'should create an endpoint for /login' do
            ep = Bubbles::Endpoint.new(:post, 'login', false, true)

            expect(ep.get_key_string).to eq('post-login-unauthenticated-with-api-key')
          end
        end
      end
    end
  end

  describe '#is_complex' do
    context 'after having created an endpoint at /versions/new' do
      it 'should show that the endpoint is complex' do
        ep = Bubbles::Endpoint.new(:get, '/versions/new')

        expect(ep.location).to eq('versions/new')
        expect(ep.is_complex?).to eq(true)
      end
    end
  end

  describe '#get_location' do
    context 'with an endpoint that is complex' do
      it 'should replace all instances of / with _ in the location string' do
        ep = Bubbles::Endpoint.new :get, 'versions'

        expect(ep.get_location_string).to eq('versions')

        ep = Bubbles::Endpoint.new :get, '/management/clients/new'

        expect(ep.get_location_string).to eq('management_clients_new')
      end
    end
  end
end
